
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_currency',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CURRENCY_ID'
) }}

with source as (
    select
        ID AS DIM_CURRENCY_ID,
        NAME AS CURRENCY_NAME,
        SYMBOL AS DISPLAY_SYMBOL,
        null AS IS_INACTIVE,
        NULL AS IS_BASE_CURRENCY,
        UPDATED_AT AS LAST_MODIFIED_DATE   

    from {{ get_silver_source(company, 'CURRENCY') }}
    
    {% if is_incremental() %}
    and UPDATED_AT > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source