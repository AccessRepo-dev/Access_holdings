{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "paycom") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
        database=get_target_database(company),
        alias ="fact_payroll_workhours",
        incremental_strategy="merge",
    )
}}

with
    bASe_punches AS (
        select
            eecode,
            punchtime::date AS work_date,
            punchtime::timestamp_ntz AS punch_timestamp,
            punchtype,
            row_number() over (
                partition by eecode, punchtime::date order by punchtime
            ) AS punch_order
        from {{ ref("paycom_punch_history") }}
        where upper(punchtype) in ('ID', 'OD', 'HR')
    ),

    -- Identify punch pairs (ID followed by OD)
    punch_pairs AS (
        select
            curr.eecode,
            curr.work_date,
            curr.punch_timestamp AS in_time,
            next_punch.punch_timestamp AS out_time,
            timestampdiff(second, curr.punch_timestamp, next_punch.punch_timestamp)
            / 3600.0 AS hours_worked
        from bASe_punches curr
        left join
            bASe_punches next_punch
            on curr.eecode = next_punch.eecode
            and curr.work_date = next_punch.work_date
            and next_punch.punch_order = curr.punch_order + 1
            and next_punch.punchtype = 'OD'
        where curr.punchtype = 'ID'
    ),

    -- HR entries
    hr_hours AS (
        select eecode, work_date, null AS in_time, null AS out_time, 8.0 AS hours_worked
        from bASe_punches
        where punchtype = 'HR'
    ),

    -- Combine all
    combined_hours AS (
        select *
        from punch_pairs
        where out_time is not null
        union all 
        select *
        from hr_hours
    ),

    hours_worked AS (
        select
            eecode,
            work_date,
            round(sum(hours_worked), 2) AS total_hours_worked,
            count(*) AS shift_count,
            min(in_time) AS first_punch_in,
            max(out_time) AS lASt_punch_out,
            listagg(
                CASE
                    WHEN in_time is not null
                    THEN
                        to_varchar(in_time, 'HH24:MI')
                        || '-'
                        || to_varchar(out_time, 'HH24:MI')
                    ELSE 'HR Entry (8h)'
                END,
                ' | '
            ) within group (order by in_time) AS shift_details
        from combined_hours
        group by eecode, work_date  -- ADD THIS LINE - it wAS missing!
    ),
    hours_worked_wB AS (
        select
            h.eecode,
            h.work_date,
            round(sum(h.hours_worked) over (
                partition by h.eecode, 
                case
            when esil.pay_frequency = 'W'
                then dateadd(day, -mod(datediff(day, '2022-12-31'::date, h.work_date), 7), h.work_date)
            when esil.pay_frequency = 'B'
                then dateadd(day, -mod(datediff(day, '2022-12-31'::date, h.work_date), 14), h.work_date)
            else date_trunc('month', h.work_date)
            end
            ), 2) as period_total_hours,
            count(distinct h.work_date) over (
            partition by h.eecode,
            case
                when esil.pay_frequency = 'W'
                    then dateadd(day, -mod(datediff(day, '2022-12-31'::date, h.work_date), 7), h.work_date)
                when esil.pay_frequency = 'B'
                    then dateadd(day, -mod(datediff(day, '2022-12-31'::date, h.work_date), 14), h.work_date)
                else date_trunc('month', h.work_date)
            end
        ) as period_distinct_days
        from combined_hours h
        left join {{ ref("paycom_employees") }} esil
            on esil.eecode = h.eecode
    ),
    source AS (
        select
            es.annual_salary AS annual_salary,
            null AS currency_code,
            h.eecode AS dim_employee_id,
            h.eecode AS employee_id,
            e.dim_company_id,
            e.dim_location_id,
            e.dim_job_id,
            null AS dim_organization_level_id,
            CAST(null AS float) AS total_tax_amount,
            CAST(null AS float) AS net_amount,
            CAST(null AS float) AS bonus_total_hours,
            es.hourly_salary AS hourly_pay_rate,
            CAST(null AS float) AS total_deduction_amount,
            CASE
                WHEN e.scheduled_work_hours = 0 and e.employee_type = 'Full Time' and  esil.pay_frequency = 'B'
                THEN 80/wb.period_distinct_days
                WHEN e.scheduled_work_hours = 0 and e.employee_type = 'Full Time' and  esil.pay_frequency = 'W'
                THEN 40/wb.period_distinct_days
                WHEN e.scheduled_work_hours = 0
                THEN h.total_hours_worked
                WHEN esil.pay_frequency = 'B'
                THEN e.scheduled_work_hours / wb.period_distinct_days
                WHEN esil.pay_frequency = 'W'
                THEN e.scheduled_work_hours / wb.period_distinct_days
            END AS total_hours,  -- Standard hours expected

            case
                when shift_details <> 'HR Entry (8h)' then
                    case
                        when esil.pay_frequency = 'W' and period_total_hours > 40
                            then (wb.period_total_hours - 40) / wb.period_distinct_days
                        when esil.pay_frequency = 'B' and period_total_hours > 80
                            then (wb.period_total_hours - 80) / wb.period_distinct_days
                        else 0
                    end
                else 0
            end as bonus_total_ot_hours,
            

            CASE 
                WHEN h.shift_details = 'HR Entry (8h)' THEN 0 
                ELSE h.total_hours_worked - bonus_total_ot_hours
            END AS total_hours_worked, 


            CASE
                WHEN h.shift_details = 'HR Entry (8h)' THEN h.total_hours_worked ELSE 0
            END AS paid_absence_hours,  


            CAST(null AS float) AS unpaid_absence_hours,
            CASE
                WHEN es.pay_clASs in ('SAL', 'RIS')
                THEN annual_salary / 250
                WHEN bonus_total_ot_hours is null
                THEN (h.total_hours_worked) * es.hourly_salary
                ELSE (bonus_total_ot_hours + h.total_hours_worked) * es.hourly_salary
            END AS total_earnings_amount,
            h.work_date AS pay_date,
            current_timestamp()::timestamp_ntz AS gold_load_date
        from hours_worked h
        left join hours_worked_wB wb on h.eecode = wb.eecode and h.work_date = wb.work_date
        left join {{ ref("paycom_dim_employee") }} e on e.dim_employee_id = h.eecode
        left join {{ ref("paycom_employee_sensitive") }} es on es.eecode = h.eecode
        left join {{ ref("paycom_employees") }} esil on esil.eecode = h.eecode
   
    )

select *
from source
