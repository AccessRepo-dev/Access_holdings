{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
 
      
{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database = get_target_database(company),
    alias = sourcesystem ~ '_OPPORTUNITY',
    schema = 'silver',
    unique_key = 'ID_DATE_KEY',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    on_schema_change='sync_all_columns'
) }}

with raw as 
(
select *
from {{ ref('salesforce_opportunity_snapshot') }}
    {% if is_incremental()%}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}
    
),


cleaned as 
(
select
    CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
    TRIM(ID) AS ID,
    TRIM(ACCOUNT_ID) AS ACCOUNT_ID,
    TRIM(OWNER_ID) AS OWNER_ID,
    TRIM(NAME) AS NAME,
    TRIM(STAGE_NAME) AS STAGE_NAME,
    AMOUNT,
    INSTALL_AMOUNT_C,
    CLOSE_DATE,
    PROBABILITY,
    TRIM(LEAD_SOURCE) AS LEAD_SOURCE,
    TRIM(CAMPAIGN_ID) AS CAMPAIGN_ID,
    TRIM(FORECAST_CATEGORY_NAME) AS FORECAST_CATEGORY_NAME,
    TRIM(SYSTEM_SUB_TYPE_C) as SYSTEM_SUB_TYPE_C, 
    TOTAL_CONTRACT_VALUE_CURRENCY_C,
    IS_CLOSED,
    IS_WON,
    NEXT_STEP,
    CREATED_DATE,
    TRIM(DESCRIPTION) AS DESCRIPTION,
    LOSS_REASON_C, 
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    _FIVETRAN_SYNCED::timestamp_ntz  AS _FIVETRAN_SYNCED,
    CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
from raw
)

SELECT * FROM cleaned