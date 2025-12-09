{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    enabled=false,
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (

    select
        ID_DATE_KEY,
        CONTACT_ID,
        ACCOUNT_ID,
        FIRST_NAME,
        LAST_NAME,
        EMAIL,
        PHONE,
        CREATED_DATE,
        LAST_MODIFIED_DATE,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, 'SALESFORCE_CONTACT') }}

    {% if is_incremental() %}
        WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}
)
select *
from source