{% set company = var('company', 'playfly') | lower %}
{{ config(enabled = var('sourcesystem', 'ukg_pro') | lower == 'ukg_pro') }}

{{ config(
    database = get_target_database(company),
    alias = 'fact_payroll_workhours',
    incremental_strategy = 'merge',
) }}

with source as (
    select
        ANNUAL_SALARY,
        CURRENCY_CODE,
        EMPLOYEE_ID,
        HOURLY_PAY_RATE,
        TOTAL_DEDUCTION_AMOUNT,
        TOTAL_EARNINGS_AMOUNT,
        TOTAL_HOURS,
        TOTAL_HOURS_WORKED,
        PAY_DATE
    from {{ref('ukg_pro_pay_register')}}
 where _fivetran_deleted = false
)
select *
from source