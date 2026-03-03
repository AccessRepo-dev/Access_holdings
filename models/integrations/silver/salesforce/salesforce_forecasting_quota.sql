{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
 
      
{{
    config(
    enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"] and (var("company", "zeus") | lower) in ["zeus"],
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
select         {{ sf_canonical_forecasting_quota(company, sourcesystem) }},
        _FIVETRAN_DELETED,
        _fivetran_synced,
        current_timestamp() as silver_load_date
from {{ get_raw_source(company, sourcesystem, 'FORECASTING_QUOTA') }}
    {% if is_incremental()%}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}

),


cleaned as 
(
select
    TRIM(ID) AS ID,
    TRIM(QUOTA_OWNER_ID) AS QUOTA_OWNER_ID,
    UPPER(TRIM(PRODUCT_FAMILY)) AS PRODUCT_FAMILY,
    TRIM(PERIOD_ID)  AS PERIOD_ID,
    TRIM(FORECASTING_TYPE_ID) AS FORECASTING_TYPE_ID,
    TRIM(FORECASTING_GROUP_ITEM_ID) AS FORECASTING_GROUP_ITEM_ID,
    START_DATE::DATE AS START_DATE,
    /* Normalize booleans */
    COALESCE(IS_AMOUNT, FALSE) AS IS_AMOUNT,
    COALESCE(IS_QUANTITY, FALSE) AS IS_QUANTITY,
    /* Numeric hygiene */
    ROUND(QUOTA_AMOUNT, 2) AS QUOTA_AMOUNT,
    ROUND(QUOTA_QUANTITY, 2) AS QUOTA_QUANTITY,
    CAST(CREATED_DATE AS TIMESTAMP_NTZ) AS CREATED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    _FIVETRAN_SYNCED::timestamp_ntz  AS _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
 
from raw
)

select * from cleaned