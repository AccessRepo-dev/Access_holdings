
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CURRENCY_ID'
) }}

with source as (
    select
        ID AS DIM_CURRENCY_ID,
        NAME AS CURRENCY_NAME,
        SYMBOL AS DISPLAY_SYMBOL,
        UPDATED_AT AS LAST_MODIFIED_DATE   

    from {{ get_silver_source(company, 'sage_currency') }}
    
    {% if is_incremental() %}
    and UPDATED_AT > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source