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
            h.eecode,
            punchtime::date AS work_date,
            punchtime::timestamp_ntz AS punch_timestamp,
            punchtype,
            row_number() over (
                partition by h.eecode, punchtime::date order by punchtime
            ) AS punch_order
        from {{ ref("paycom_punch_history") }} h
        left join {{ ref("paycom_employees") }} esil on esil.eecode = h.eecode
        where upper(punchtype) in ('ID', 'OD', 'HR')
        and coalesce(exempt_status, 'Unknown') <>'Exempt'
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
        QUALIFY ROW_NUMBER() OVER (PARTITION BY h.eecode, h.work_date ORDER BY h.work_date) = 1
    ),
    date_spine AS (
    SELECT 
        DATE_VALUE,
        DAYOFWEEK(DATE_VALUE) AS day_of_week,
        CASE WHEN DAYOFWEEK(DATE_VALUE) BETWEEN 1 AND 5 THEN 1 ELSE 0 END AS is_weekday
    FROM (
        SELECT DATEADD(DAY, SEQ4(), '2020-01-01'::DATE) AS DATE_VALUE
        FROM TABLE(GENERATOR(ROWCOUNT => 3650))  -- ~10 years
    )
    WHERE DATE_VALUE <= CURRENT_DATE()
),
    non_punch_record_employees as (
        select 
            es.annual_salary AS annual_salary,
            null AS currency_code,
            dim_employee_id,
            dim_employee_id AS employee_id,
            CAST(null AS float) AS total_tax_amount,
            
            CAST(null AS float) AS bonus_total_hours,
            es.annual_salary/2080 AS hourly_pay_rate,
            CAST(null AS float) AS total_deduction_amount,
            8  as total_hours,  -- Standard hours expected
            0 as bonus_total_ot_hours,
        
            8 as total_hours_worked, 
            0 as paid_absence_hours,  


            CAST(null AS float) AS unpaid_absence_hours,
            total_hours_worked * hourly_pay_rate as total_earnings_amount,
            CAST(total_earnings_amount AS float) AS net_amount,
            d.DATE_VALUE AS pay_date,
            current_timestamp()::timestamp_ntz AS gold_load_date

        from 
        {{ ref("paycom_dim_employee") }} e 
        left join {{ ref("paycom_employee_sensitive") }} es on es.eecode = e.dim_employee_id
        left join date_spine d on d.DATE_VALUE between  e.hire_date AND COALESCE(e.termination_date, CURRENT_DATE())
        left join {{ ref("paycom_employees") }} esil on esil.eecode = es.eecode
        where coalesce(exempt_status, 'Unknown') = 'Exempt'--dim_employee_id not in (select distinct eecode from hours_worked)
        and IS_WEEKDAY = 1
    )
    ,
    source AS (
        select
            es.annual_salary AS annual_salary,
            null AS currency_code,
            h.eecode AS dim_employee_id,
            h.eecode AS employee_id,
            CAST(null AS float) AS total_tax_amount,
            
            CAST(null AS float) AS bonus_total_hours,

            COALESCE( nullif(es.hourly_salary,0),
            case when nullif(es.last_pay_rate,0) > 100 then es.last_pay_rate/2080 else es.last_pay_rate end,es.annual_salary/2080)  AS hourly_pay_rate,
            CAST(null AS float) AS total_deduction_amount,
            -- Standard hours expected

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
                WHEN h.shift_details = 'HR Entry (8h)' THEN h.total_hours_worked ELSE 0
            END AS paid_absence_hours,  


            CAST(null AS float) AS unpaid_absence_hours,

            h.work_date AS pay_date,
            shift_details,
            scheduled_work_hours,
            period_distinct_days,
            total_hours_worked as raw_total_hours_worked,
            current_timestamp()::timestamp_ntz AS gold_load_date
        from hours_worked h
        left join hours_worked_wB wb on h.eecode = wb.eecode and h.work_date = wb.work_date
        left join {{ ref("paycom_dim_employee") }} e on e.dim_employee_id = h.eecode
        left join {{ ref("paycom_employee_sensitive") }} es on es.eecode = h.eecode
        left join {{ ref("paycom_employees") }} esil on esil.eecode = h.eecode
         
        
   
    ),
    hours_cal as 
    (   
        Select *, 
         CASE 
                WHEN shift_details = 'HR Entry (8h)' THEN 0 
                ELSE raw_total_hours_worked - bonus_total_ot_hours
            END AS total_hours_worked
        from source
    )
select annual_salary, 
        currency_code, 
        dim_employee_id, 
        employee_id,
        total_tax_amount, 
        bonus_total_hours, 
        hourly_pay_rate, 
        total_deduction_amount,
        bonus_total_ot_hours,
        total_hours_worked,  
            CASE
                WHEN scheduled_work_hours = 0 then total_hours_worked
                ELSE scheduled_work_hours / period_distinct_days 
            END AS total_hours,
        paid_absence_hours, 
        unpaid_absence_hours,
        (bonus_total_ot_hours + total_hours_worked) * hourly_pay_rate as total_earnings_amount,
           CAST(total_earnings_amount AS float) AS net_amount,
        pay_date, 
        gold_load_date
from hours_cal
    union all
    select annual_salary, 
        currency_code, 
        dim_employee_id, 
        employee_id,
        total_tax_amount, 
        bonus_total_hours, 
        hourly_pay_rate, 
        total_deduction_amount,
        bonus_total_ot_hours,
        total_hours_worked, 
        total_hours,
        paid_absence_hours, 
        unpaid_absence_hours,
        total_earnings_amount,
        net_amount,
        pay_date, 
        gold_load_date
        from non_punch_record_employees