{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_currency',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CURRENCY_ID'
) }}

with source as (
    select 
    ID AS DIM_CURRENCY_ID,
    NAME AS CURRENCY_NAME,
    SYMBOL AS DISPLAY_SYMBOL,
    ISINACTIVE AS IS_INACTIVE,
    ISBASECURRENCY AS IS_BASE_CURRENCY,
    LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,
from {{ get_silver_source(company, 'CURRENCY') }}
    where (_fivetran_deleted is null or _fivetran_deleted = false)
    {% if is_incremental() %}
    and LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source