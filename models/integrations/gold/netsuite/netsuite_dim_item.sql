{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_item',
    incremental_strategy = 'merge',
    unique_key = 'DIM_ITEM_ID'
) }}

with source as (
    select
        ID AS DIM_ITEM_ID,
        FULLNAME AS ITEM_NAME,
        DISPLAYNAME AS DISPLAY_NAME,
        DISPLAYNAME AS STORE_DISPLAY_NAME,
        DESCRIPTION AS DESCRIPTION,
        STOCKDESCRIPTION AS STORE_DESCRIPTION,
        ITEMTYPE AS ITEM_TYPE,
        SUBTYPE AS SUB_TYPE,
        CLASS AS CLASS_ID,
        DEPARTMENT AS DEPARTMENT_ID,
        LOCATION AS LOCATION_ID,
        SUBSIDIARY AS SUBSIDIARY_ID,
        PARENT AS PARENT_ID,
        PRICINGGROUP AS PRICING_GROUP,
        UNITSTYPE AS UNITS_TYPE,
        INCOMEACCOUNT AS INCOME_ACCOUNT,
        COSTINGMETHOD AS COSTING_METHOD,
        COST AS COST,
        LASTPURCHASEPRICE AS LAST_PURCHASE_PRICE,
        AVERAGECOST AS AVERAGE_COST,
        QUANTITYAVAILABLE AS TOTAL_QUANTITY_ON_HAND,
        TOTALVALUE AS TOTAL_VALUE,
        SALEUNIT AS SALE_UNIT,
        STOCKUNIT AS STOCK_UNIT,
        SHIPPINGCOST AS SHIPPING_COST,
        VENDORNAME AS VENDOR_NAME,
        MANUFACTURER AS MANUFACTURER,
        MAXIMUMQUANTITY AS MAXIMUM_QUANTITY,
        WEIGHT AS WEIGHT,
        ISFULFILLABLE AS IS_FULFILLABLE,
        ISINACTIVE AS IS_INACTIVE,
        CREATEDDATE AS CREATED_DATE,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE
    from {{ get_silver_source(company, 'ITEM') }}
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