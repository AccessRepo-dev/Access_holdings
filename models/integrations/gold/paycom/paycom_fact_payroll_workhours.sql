{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "paycom") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
        database=get_target_database(company),
        alias="fact_payroll_workhours",
        incremental_strategy="merge",
    )
}}

with
    base_punches as (
        select
            eecode,
            punchtime::date as work_date,
            punchtime::timestamp_ntz as punch_timestamp,
            punchtype,
            row_number() over (
                partition by eecode, punchtime::date order by punchtime
            ) as punch_order
        from {{ ref("paycom_punch_history") }}
        where upper(punchtype) in ('ID', 'OD', 'HR')
    ),

    -- Identify punch pairs (ID followed by OD)
    punch_pairs as (
        select
            curr.eecode,
            curr.work_date,
            curr.punch_timestamp as in_time,
            next_punch.punch_timestamp as out_time,
            timestampdiff(second, curr.punch_timestamp, next_punch.punch_timestamp)
            / 3600.0 as hours_worked
        from base_punches curr
        left join
            base_punches next_punch
            on curr.eecode = next_punch.eecode
            and curr.work_date = next_punch.work_date
            and next_punch.punch_order = curr.punch_order + 1
            and next_punch.punchtype = 'OD'
        where curr.punchtype = 'ID'
    ),

    -- HR entries
    hr_hours as (
        select eecode, work_date, null as in_time, null as out_time, 8.0 as hours_worked
        from base_punches
        where punchtype = 'HR'
    ),

    -- Combine all
    combined_hours as (
        select *
        from punch_pairs
        where out_time is not null
        union all
        select *
        from hr_hours
    ),

    hours_worked as (
        select
            eecode,
            work_date,
            round(sum(hours_worked), 2) as total_hours_worked,
            count(*) as shift_count,
            min(in_time) as first_punch_in,
            max(out_time) as last_punch_out,
            listagg(
                case
                    when in_time is not null
                    then
                        to_varchar(in_time, 'HH24:MI')
                        || '-'
                        || to_varchar(out_time, 'HH24:MI')
                    else 'HR Entry (8h)'
                end,
                ' | '
            ) within group (order by in_time) as shift_details
        from combined_hours
        group by eecode, work_date  -- ADD THIS LINE - it was missing!
    ),

    source as (
        select
            es.annual_salary as annual_salary,
            null as currency_code,
            h.eecode as dim_employee_id,
            h.eecode as employee_id,
            e.dim_company_id,
            e.dim_location_id,
            e.dim_job_id,
            null as dim_organization_level_id,
            cast(null as float) as total_tax_amount,
            cast(null as float) as net_amount,
            cast(null as float) as bonus_total_hours,
            es.hourly_salary as hourly_pay_rate,
            cast(null as float) as total_deduction_amount,
            e.scheduled_work_hours as total_hours,  -- Standard hours expected
            h.total_hours_worked,  -- REMOVE SUM() - already aggregated
            cast(null as float) as bonus_total_ot_hours,
            case
                when h.shift_details = 'HR Entry (8h)' then h.total_hours_worked else 0
            end as paid_absence_hours,  -- REMOVE SUM() - already aggregated
            cast(null as float) as unpaid_absence_hours,
            case
                when pay_class in ('SAL', 'RIS')
                then annual_salary / 250
                when bonus_total_ot_hours is null then (h.total_hours_worked) * es.hourly_salary
                else (bonus_total_ot_hours + h.total_hours_worked) * es.hourly_salary
            end as total_earnings_amount,
            h.work_date as pay_date,
            current_timestamp()::timestamp_ntz as gold_load_date
        from hours_worked h
        left join {{ ref("paycom_dim_employee") }} e on e.dim_employee_id = h.eecode
        left join {{ ref("paycom_employee_sensitive") }} es on es.eecode = h.eecode
    -- REMOVE GROUP BY - hours_worked already has one row per employee per day
    )

select *
from source
