{% set company = var('company','zeus') %}
{% set sourcesystem = var('sourcesystem','salesforce') %}
{{ config(enabled = var('sourcesystem', 'salesforce') == 'salesforce' and var('company','zeus') == 'zeus') }}

{{ config(
    enabled = var('sourcesystem', 'none') == 'salesforce',
    database = get_target_database(company),
    schema = 'silver',
    unique_key = 'ID_DATE_KEY',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    on_schema_change='sync_all_columns'
) }}

with raw as 
(
select *
from {{ source_snapshot_schema(company, 'SALESFORCE_OPPORTUNITY') }}
{% if is_incremental() %}
    where 
        (cast(LAST_MODIFIED_DATE as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)) from {{ this }})
    OR 
        (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))

{% else %}
    where 1=1
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
    IS_CLOSED,
    IS_WON,
    NEXT_STEP,
    CREATED_DATE,
    TRIM(DESCRIPTION) AS DESCRIPTION,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
from raw
)

SELECT * FROM cleaned