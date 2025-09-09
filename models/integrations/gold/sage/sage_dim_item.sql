
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_ITEM_ID'
) }}

with source as (
    select
        RECORDNO AS DIM_ITEM_ID,
        ITEMID AS ITEM_ID,
        NAME AS ITEM_NAME,
        EXTENDED_DESCRIPTION AS DESCRIPTION,
        ITEMTYPE AS ITEM_TYPE,
        COST_METHOD AS COSTING_METHOD,
        STANDARD_COST AS COST,
        STATUS AS IS_INACTIVE,
        WHENCREATED AS CREATED_DATE,
        WHENMODIFIED AS LAST_MODIFIED_DATE
  

    from {{ get_silver_source(company, 'sage_item') }}
    
    {% if is_incremental() %}
    and WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source