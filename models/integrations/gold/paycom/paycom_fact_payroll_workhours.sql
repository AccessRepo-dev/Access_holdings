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
                WHEN e.scheduled_work_hours = 0 and e.employee_type = 'Full Time'
                THEN 8
                WHEN e.scheduled_work_hours = 0
                THEN h.total_hours_worked
                WHEN esil.pay_frequency = 'B'
                THEN e.scheduled_work_hours / 10
                WHEN esil.pay_frequency = 'W'
                THEN e.scheduled_work_hours / 5
            END AS total_hours,  -- Standard hours expected


             -- REMOVE SUM() - already aggregated

            CASE WHEN  total_hours_worked > total_hours AND h.shift_details <> 'HR Entry (8h)'  THEN total_hours_worked - total_hours 
                ELSE 0 
            END AS bonus_total_ot_hours,

            CASE 
                WHEN h.shift_details = 'HR Entry (8h)' THEN 0 
                WHEN  total_hours_worked > total_hours THEN  total_hours 
                ELSE h.total_hours_worked
            END AS total_hours_worked, 


            CASE
                WHEN h.shift_details = 'HR Entry (8h)' THEN h.total_hours_worked ELSE 0
            END AS paid_absence_hours,  -- REMOVE SUM() - already aggregated
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
        left join {{ ref("paycom_dim_employee") }} e on e.dim_employee_id = h.eecode
        left join {{ ref("paycom_employee_sensitive") }} es on es.eecode = h.eecode
        left join {{ ref("paycom_employees") }} esil on esil.eecode = h.eecode
   
    )

select *
from source
