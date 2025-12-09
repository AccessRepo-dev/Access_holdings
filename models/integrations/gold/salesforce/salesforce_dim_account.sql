{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    enabled = false,
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_account',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (

    select
        ID_DATE_KEY,
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
        DBT_VALID_FROM,
        DBT_VALID_TO,
        Is_Active,
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