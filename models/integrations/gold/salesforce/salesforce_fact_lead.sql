{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'fact_lead',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (


    select
        sl.ID_DATE_KEY,
        sl.LEAD_ID,
        sl.CREATED_DATE AS LEAD_DATE,
        sl.owner_id AS OWNER_ID,
        sl.COMPANY,
        sl.STATUS,
        sl.IS_ACTIVE,
        sl.converted_opportunity_id AS CONVERTED_OPPORTUNITY_KEY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    FROM {{ get_silver_source(company, 'SALESFORCE_LEAD') }} sl

    {% if is_incremental() %}
        WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}


)
select *
from source