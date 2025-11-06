{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'salesforce',
    database = get_target_database(company),
    schema = 'silver',
    unique_key = 'id',
    materialized = 'incremental',
    incremental_strategy = 'merge'
) }}

with raw as 
(
select *

from {{ source_snapshot_schema(company, 'SALESFORCE_OPPORTUNITY') }}
{% if is_incremental() %}
    where 
        LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
            from {{ this }})
        and DBT_VALID_TO is null
{% else %}
    where DBT_VALID_TO is null
{% endif %}
    
)

select
    TRIM(ID) AS ID,
    TRIM(ACCOUNT_ID) AS ACCOUNT_ID,
    TRIM(OWNER_ID) AS OWNER_ID,
    TRIM(NAME) AS NAME,
    TRIM(STAGE_NAME) AS STAGE_NAME,
    AMOUNT,
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
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
from raw
