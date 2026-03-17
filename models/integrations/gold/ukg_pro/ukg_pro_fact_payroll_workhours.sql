{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly","spotless"],
        database=get_target_database(company),
        alias="fact_payroll_workhours",
        incremental_strategy="merge",
    )
}}

with
    source as (
        select
            annual_salary,
            currency_code,
            hash(concat(p.employee_id, p.company_id)) as dim_employee_id,
            p.employee_id,
            total_tax_amount,
            net_amount,
            bonus_total_hours,
            bonus_total_ot_hours,
            hourly_pay_rate,
            total_deduction_amount,
            total_earnings_amount,
            e.SCHEDULED_WORK_HRS as total_hours,
            total_hours as total_hours_worked,
            cast(null as int) as unpaid_absence_hours,
            cast(null as int) as paid_absence_hours,
            pay_date,
            current_timestamp()::timestamp_ntz AS gold_load_date
        from {{ ref("ukg_pro_pay_register") }} p
        left join {{ref("ukg_pro_employment")}} e on e.employee_id = p.employee_id and e.company_id = p.company_id
        where p._fivetran_deleted = false and e._fivetran_deleted = false and total_earnings_amount <> 0 and total_hours <> 0
    )
select *
from source
