
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
        NAME AS ITEM_NAME,
        NAME AS DISPLAY_NAME,
        NULL AS STORE_DISPLAY_NAME,
        EXTENDED_DESCRIPTION AS DESCRIPTION,
        NULL AS STORE_DESCRIPTION,
        ITEMTYPE AS ITEM_TYPE,
        NULL AS SUB_TYPE,
        NULL AS CLASS_ID,
        NULL AS DEPARTMENT_ID,
        NULL AS LOCATION_ID,
        NULL AS SUBSIDIARY_ID,
        NULL AS PARENT_ID,
        NULL AS PRICING_GROUP,
        NULL AS UNITS_TYPE,
        NULL AS INCOME_ACCOUNT,
        COST_METHOD AS COSTING_METHOD,
        STANDARD_COST AS COST,
        NULL AS LAST_PURCHASE_PRICE,
        NULL AS AVERAGE_COST,
        NULL AS TOTAL_QUANTITY_ON_HAND,
        NULL AS TOTAL_VALUE,
        NULL AS SALE_UNIT,
        NULL AS STOCK_UNIT,
        NULL AS SHIPPING_COST,
        NULL AS VENDOR_NAME,
        NULL AS MANUFACTURER,
        NULL AS MAXIMUM_QUANTITY,
        NULL AS WEIGHT,
        ENABLEFULFILLMENT AS IS_FULFILLABLE,
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