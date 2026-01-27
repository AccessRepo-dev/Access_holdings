{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
 
      
{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~ '_FORECASTING_QUOTA',
    schema = 'silver',
    incremental_strategy = 'merge',
    unique_key = 'ID',
    on_schema_change='sync_all_columns'
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'FORECASTING_QUOTA') }}
),


cleaned as 
(
select
 TRIM(ID)                                      AS ID,
    TRIM(QUOTA_OWNER_ID)                       AS QUOTA_OWNER_ID,
    UPPER(TRIM(PRODUCT_FAMILY))                AS PRODUCT_FAMILY,

    TRIM(PERIOD_ID)                            AS PERIOD_ID,
    TRIM(FORECASTING_TYPE_ID)                  AS FORECASTING_TYPE_ID,
    TRIM(FORECASTING_GROUP_ITEM_ID)            AS FORECASTING_GROUP_ITEM_ID,

    START_DATE::DATE                           AS START_DATE,

    /* Normalize booleans */
    COALESCE(IS_AMOUNT, FALSE)                 AS IS_AMOUNT,
    COALESCE(IS_QUANTITY, FALSE)               AS IS_QUANTITY,

    /* Numeric hygiene */
    ROUND(QUOTA_AMOUNT, 2)                     AS QUOTA_AMOUNT,
    ROUND(QUOTA_QUANTITY, 2)                   AS QUOTA_QUANTITY,

    CAST(CREATED_DATE AS TIMESTAMP_NTZ)                AS CREATED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ)         AS LAST_MODIFIED_DATE,
    _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
 
from raw
)

select * from cleaned