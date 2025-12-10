{% set company = var('company', 'zeus') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_user',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (

    select
        ID_DATE_KEY,
        ID AS USER_ID,
        NAME,
        -- USERNAME,
        -- EMAIL,
        -- FIRST_NAME,
        -- LAST_NAME,
        USER_IS_ACTIVE,
        -- USER_ROLE_ID,
        LAST_MODIFIED_DATE,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, 'SALESFORCE_USER') }}

    {% if is_incremental() %}
        WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}
)
select *
from source