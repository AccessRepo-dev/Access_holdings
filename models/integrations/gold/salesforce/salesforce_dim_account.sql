{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ACCOUNT_ID'
) }}

with source as (

    select
        ACCOUNT_ID,
        NAME,
        TYPE,
        INDUSTRY,
        ANNUAL_REVENUE,
        NUMBER_OF_EMPLOYEES,
        OWNER_ID,
        BILLING_CITY,
        SHIPPING_CITY,
        CREATED_DATE,
        LAST_MODIFIED_DATE,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, 'SALESFORCE_ACCOUNT') }}

    {% if is_incremental() %}
        WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}
)
select *
from source