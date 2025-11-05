{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['salesforce']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = 'QUOTE_LINE_ITEM',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

select
    TRIM(ID) AS ID,
    TRIM(PRODUCT_2_ID) AS PRODUCT_2_ID,
    QUANTITY,
    UNIT_PRICE,
    SERVICE_DATE,
    DISCOUNT,
    TOTAL_PRICE,
    CREATED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE
from {{ get_raw_source(company, sourcesystem, 'QUOTE_LINE_ITEM') }}
    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
