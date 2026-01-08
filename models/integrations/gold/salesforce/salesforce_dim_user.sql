{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
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
        -- USER_IS_ACTIVE,
        -- USER_ROLE_ID,
        -- LAST_MODIFIED_DATE,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE,
        CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ ref('salesforce_user_current') }}

    {% if is_incremental() %}
        WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}
)
select *
from source