{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database = get_target_database(company),
    alias = 'dim_product',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (

    select
        ID_DATE_KEY,
        PRODUCT_ID,
        NAME,
        PRODUCT_CODE,
        FAMILY,
        DESCRIPTION,
        PRODUCT_IS_ACTIVE,
        LAST_MODIFIED_DATE,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ ref('salesforce_product_current') }}

    {% if is_incremental() %}
        WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}
)
select *
from source