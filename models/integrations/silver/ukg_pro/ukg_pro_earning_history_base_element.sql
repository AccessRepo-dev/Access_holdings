{% set company = var('company', 'playfly') | lower %}
{% set sourcesystem  = var('sourcesystem', 'ukg_pro') | lower %}
{{ config(enabled = var('sourcesystem', 'ukg_pro') == 'ukg_pro') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key=['company_id', 'employee_id']
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'EARNING_HISTORY_BASE_ELEMENT') }}
    {% if is_incremental() %}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    {% endif %}
),

cleaned as (
   SELECT
    TRIM(_FIVETRAN_ID)                                         AS _FIVETRAN_ID,
    CAST(_FIVETRAN_DELETED AS BOOLEAN)                         AS _FIVETRAN_DELETED,
    TRIM(COMPANY_ID)                                           AS COMPANY_ID,
    TRIM(EARNING_ID)                                           AS EARNING_ID,
    TRIM(EMPLOYEE_ID)                                          AS EMPLOYEE_ID,
    TRIM(EMPLOYMENT_ID)                                        AS EMPLOYMENT_ID,
    TRIM(JOB_ID)                                               AS JOB_ID,
    TRIM(LOCATION_ID)                                          AS LOCATION_ID,
    TRIM(PAY_GROUP)                                            AS PAY_GROUP,
    -- CAST(_FIVETRAN_SYNCED AS TIMESTAMP_TZ)                     AS _FIVETRAN_SYNCED,
    -- CAST(INCLUDE_IN_DEFERRED_COMPENSATION AS BOOLEAN)          AS INCLUDE_IN_DEFERRED_COMPENSATION,
    -- TRIM(ACCRUAL_CODE)                                         AS ACCRUAL_CODE,
    -- TRIM(PROJECT)                                              AS PROJECT,
    -- TRIM(GEN_NUMBER)                                           AS GEN_NUMBER,
    -- CAST(CALCULATION_SEQUENCE AS INT)                          AS CALCULATION_SEQUENCE,
    -- CAST(JOB_PREMIUM_AMOUNT AS FLOAT)                          AS JOB_PREMIUM_AMOUNT,
    -- CAST(NUMBER_OF_GAMES AS INT)                               AS NUMBER_OF_GAMES,
    CAST(BASE_AMOUNT AS FLOAT)                                 AS BASE_AMOUNT,
    CAST(PIECE_PAY_RATE AS FLOAT)                              AS PIECE_PAY_RATE,
    -- CAST(PERIOD_CONTROL AS INT)                                AS PERIOD_CONTROL,
    -- TRIM(TIME_CLOCK_CODE)                                      AS TIME_CLOCK_CODE,
    -- CAST(GROSS_UP_TARGET AS FLOAT)                             AS GROSS_UP_TARGET,
    -- CAST(IS_VOIDING_RECORD AS BOOLEAN)                         AS IS_VOIDING_RECORD,
    -- CAST(PIECE_COUNT AS FLOAT)                                 AS PIECE_COUNT,
    CAST(HOURLY_PAY_RATE AS FLOAT)                             AS HOURLY_PAY_RATE,
    -- TRIM(CALCULATION_RULE)                                     AS CALCULATION_RULE,
    -- CAST(TIP_CREDIT AS FLOAT)                                  AS TIP_CREDIT,
    -- CAST(IS_VOIDED AS BOOLEAN)                                 AS IS_VOIDED,
    -- TRIM(TAX_CALCULATION_GROUP_ID)                             AS TAX_CALCULATION_GROUP_ID,
    CAST(PAY_RATE AS FLOAT)                                    AS PAY_RATE,
    -- TRIM(REPORT_CATEGORY)                                      AS REPORT_CATEGORY,
    CAST(PAY_DATE AS TIMESTAMP_NTZ)                            AS PAY_DATE,
    -- CAST(INCLUDE_IN_DEFERRED_COMPENSATION_HOURS AS BOOLEAN)    AS INCLUDE_IN_DEFERRED_COMPENSATION_HOURS,
    -- CAST(BATCH_ID AS INT)                                      AS BATCH_ID,
    CAST(PERIOD_PAY_RATE AS FLOAT)                             AS PERIOD_PAY_RATE,
    CAST(CURRENT_HOURS AS FLOAT)                               AS CURRENT_HOURS,
    -- TRIM(TIP_TYPE)                                             AS TIP_TYPE,
    -- CAST(JOB_PREMIUM_RATE_OR_PERCENT AS FLOAT)                 AS JOB_PREMIUM_RATE_OR_PERCENT,
    -- CAST(USE_DEDUCTION_OFF_SET AS BOOLEAN)                     AS USE_DEDUCTION_OFF_SET,
    -- CAST(NUMBER_OF_DAYS AS INT)                                AS NUMBER_OF_DAYS,
    -- TRIM(GROSS_UP)                                             AS GROSS_UP,
    -- CAST(YTD_SHIFT_AMOUNT AS FLOAT)                            AS YTD_SHIFT_AMOUNT,
    TRIM(TAX_CATEGORY)                                         AS TAX_CATEGORY,
    -- CAST(GROSS_UP_TAX_CALCULATION_METHOD AS INT)               AS GROSS_UP_TAX_CALCULATION_METHOD,
    -- CAST(TIP_GROSS_RECEIPTS AS FLOAT)                          AS TIP_GROSS_RECEIPTS,
    CAST(CURRENT_AMOUNT AS FLOAT)                              AS CURRENT_AMOUNT,
    -- TRIM(GL_FOLLOW_BASE_ACCOUNT_ALLOCATION)                    AS GL_FOLLOW_BASE_ACCOUNT_ALLOCATION,
    -- TRIM(PAYOUT_RATE_TYPE)                                     AS PAYOUT_RATE_TYPE,
    -- CAST(YTD_AMOUNT AS FLOAT)                                  AS YTD_AMOUNT,
            current_timestamp() as silver_load_date
FROM source_data

)

select 
    *
from cleaned
