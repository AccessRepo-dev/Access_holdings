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
        HASH(CONCAT(EMPLOYEE_ID,COMPANY_ID)) AS DIM_EMPLOYEE_COMPANY_ID,
        EMPLOYEE_ID,
        COMPANY_ID AS DIM_COMPANY_ID,
        LOCATION_ID AS DIM_LOCATION_ID,
        Organization_Level_1_ID AS DIM_ORGANIZATION_LEVEL_1_ID,
        Job_Code AS DIM_JOB_ID,
        Total_Tax_Amount,
        Net_Amount,
        bonus_total_hours ,
        bonus_total_ot_hours,
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