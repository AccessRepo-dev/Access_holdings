{% set company = var("company", "zeus") | lower %}
{{
    config(
        enabled=var("sourcesystem", "adp_workforce_now") | lower
        == "adp_workforce_now"
    )
}}

{{
    config(
        database=get_target_database(company),
        alias="fact_payroll_workhours",
        incremental_strategy="merge",
    )
}}

with

    hours_cte as (
        select
            associate_oid,
            worker_id,
            time_card_id,
            entry_date,
            wtct.pay_code,
            time_duration,
            bucket,
            try_to_number(
                regexp_substr(time_duration, 'PT([0-9]+)H', 1, 1, 'e', 1)
            ) as hours,
            try_to_number(
                regexp_substr(time_duration, '([0-9]+)M', 1, 1, 'e', 1)
            ) as minutes,
            try_to_number(
                regexp_substr(time_duration, '([0-9]+)S', 1, 1, 'e', 1)
            ) as seconds
        from {{ ref("adp_workforce_now_worker_time_card") }} wtc
        left join
            {{ ref("adp_workforce_now_worker_time_card_daily_total") }} wtct
            on wtc.id = wtct.time_card_id
        left join
            {{ ref("adp_workforce_now_dim_pay_code_mapping") }} pm
            on pm.pay_code = wtct.pay_code

    ),

    hours as (
        SELECT 
        associate_oid,
            worker_id,
            entry_date,
            case
                when bucket = 'Regular'
                then
                    sum(
                        coalesce(hours, 0)
                        + coalesce(minutes, 0) / 60
                        + coalesce(seconds, 0) / 3600
                    )
                else 0
            end as total_hours_worked,
            case
                when bucket = 'Overtime'
                then
                    sum(
                        coalesce(hours, 0)
                        + coalesce(minutes, 0) / 60
                        + coalesce(seconds, 0) / 3600
                    )
                else 0
            end as bonus_total_ot_hours,
            case
                when bucket = 'Paid Absence'
                then
                    sum(
                        coalesce(hours, 0)
                        + coalesce(minutes, 0) / 60
                        + coalesce(seconds, 0) / 3600
                    )
                else 0
            end as paid_absence_hours,
            case
                when bucket = 'Unpaid Absence'
                then
                    sum(
                        coalesce(hours, 0)
                        + coalesce(minutes, 0) / 60
                        + coalesce(seconds, 0) / 3600
                    )
                else 0
            end as unpaid_absence_hours
            FROM hours_cte
            GROUP BY 1,2,3, bucket
    )
    ,
    source as (
        select
            cast(null as int) as annual_salary,
            null as currency_code,
            hash(concat(h.worker_id, '-', h.associate_oid)) as dim_employee_id,
            h.associate_oid as employee_id,
            e.dim_company_id,
            e.dim_location_id,
            e.dim_job_id,
            null as dim_organization_level_id,
            cast(null as int) as total_tax_amount,
            cast(null as int) as net_amount,
            cast(null as int) as bonus_total_hours,
            cast(null as int) as hourly_pay_rate,
            cast(null as int) as total_deduction_amount,
            cast(null as int) as total_earnings_amount,
            8 as total_hours,
            sum(h.total_hours_worked) as total_hours_worked,
            sum(h.bonus_total_ot_hours) as bonus_total_ot_hours,
            sum(h.paid_absence_hours) as paid_absence_hours,
            sum(h.unpaid_absence_hours) as unpaid_absence_hours,
            h.entry_date as pay_date,
            current_timestamp()::timestamp_ntz as gold_load_date
        from hours h
        left join
            {{ ref("adp_workforce_now_dim_employee") }} e
            on e.employee_id = h.associate_oid
        group by
            h.worker_id,
            h.associate_oid,
            dim_company_id,
            dim_job_id,
            dim_location_id,
            dim_organization_level_id,
            entry_date
    )
select *
from source
