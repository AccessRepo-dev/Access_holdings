{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
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
            hash(concat(employee_id, company_id)) as dim_employee_id,
            employee_id,
            -- company_id  as dim_company_id,
            -- location_id as dim_location_id,
            -- job_code as dim_job_id,
            -- id as dim_organization_level_id,
            total_tax_amount,
            net_amount,
            bonus_total_hours,
            bonus_total_ot_hours,
            hourly_pay_rate,
            total_deduction_amount,
            total_earnings_amount,
            total_hours,
            total_hours_worked,
            cast(null as int) as unpaid_absence_hours,
            cast(null as int) as paid_absemce_hours,
            pay_date,
            current_timestamp()::timestamp_ntz AS gold_load_date
        from {{ ref("ukg_pro_pay_register") }}
        where _fivetran_deleted = false
    )
select *
from source
