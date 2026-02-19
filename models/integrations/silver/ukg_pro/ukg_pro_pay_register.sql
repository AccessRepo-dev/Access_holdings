{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'PAY_REGISTER') }}
),

cleaned as (
    select 
        CAST(ID AS VARCHAR) AS ID,
        CAST(ANNUAL_SALARY AS FLOAT)              AS ANNUAL_SALARY,
        
        CAST(COMPANY_ID AS TEXT)                  AS COMPANY_ID,
        CAST(CURRENCY_CODE AS TEXT)               AS CURRENCY_CODE,
        CAST(EMPLOYEE_ID AS TEXT)                 AS EMPLOYEE_ID,
        
        CAST(HOURLY_PAY_RATE AS FLOAT)             AS HOURLY_PAY_RATE,

        CAST(JOB_CODE AS TEXT)                    AS JOB_CODE,
        CAST(LOCATION_ID AS TEXT)                 AS LOCATION_ID,
        TRIM(Organization_Level_1_ID)               AS Organization_Level_1_ID,
        CAST(Total_Tax_Amount AS FLOAT) AS Total_Tax_Amount,
        CAST(Net_Amount AS FLOAT) AS Net_Amount,
        bonus_total_hours ,
        bonus_total_ot_hours,
        CAST(TOTAL_DEDUCTION_AMOUNT AS FLOAT)     AS TOTAL_DEDUCTION_AMOUNT,
        CAST(TOTAL_EARNINGS_AMOUNT AS FLOAT)      AS TOTAL_EARNINGS_AMOUNT,
        CAST(TOTAL_HOURS AS FLOAT)                AS TOTAL_HOURS,
        CAST(TOTAL_HOURS_WORKED AS FLOAT)         AS TOTAL_HOURS_WORKED,
        CAST(PAY_DATE AS TIMESTAMP_NTZ)           AS PAY_DATE,
        _FIVETRAN_DELETED
    from source_data
)

select 
    *
from cleaned
