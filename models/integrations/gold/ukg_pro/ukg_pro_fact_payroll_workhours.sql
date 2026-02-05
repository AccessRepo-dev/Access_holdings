{% set company = var("company", "playfly") | lower %}
{{ config(enabled=var("sourcesystem", "ukg_pro") | lower == "ukg_pro") }}

{{
    config(
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
            company_id  as dim_company_id,
            location_id as dim_location_id,
            job_code as dim_job_id,
            id as dim_organization_level_id,
            total_tax_amount,
            net_amount,
            bonus_total_hours,
            bonus_total_ot_hours,
            hourly_pay_rate,
            total_deduction_amount,
            total_earnings_amount,
            total_hours,
            total_hours_worked,
            pay_date
        from {{ ref("ukg_pro_pay_register") }}
        where _fivetran_deleted = false
    )
select *
from source
