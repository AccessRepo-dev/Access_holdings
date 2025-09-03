{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ITEM_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'ITEM') }}
    {% if is_incremental() %}
    where LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(ID AS INT) AS ITEM_ID,
        TRIM(ITEMID) AS ITEM_CODE,
        TRIM(DISPLAYNAME) AS DISPLAY_NAME,
        TRIM(FULLNAME) AS FULL_NAME,
        TRIM(DESCRIPTION) AS DESCRIPTION,
        TRIM(STOCKDESCRIPTION) AS STOCK_DESCRIPTION,
        TRIM(ITEMTYPE) AS ITEM_TYPE,
        TRIM(SUBTYPE) AS SUB_TYPE,
        TRIM(MANUFACTURER) AS MANUFACTURER,
        TRIM(VENDORNAME) AS VENDOR_NAME,
        TRY_CAST(CLASS AS INT) AS CLASS_ID,
        TRY_CAST(DEPARTMENT AS INT) AS DEPARTMENT_ID,
        TRY_CAST(LOCATION AS INT) AS LOCATION_ID,
        TRY_CAST(PARENT AS INT) AS PARENT_ID,
        TRY_CAST(PRICINGGROUP AS INT) AS PRICING_GROUP_ID,
        TRY_CAST(SALEUNIT AS INT) AS SALE_UNIT_ID,
        TRY_CAST(STOCKUNIT AS INT) AS STOCK_UNIT_ID,
        TRY_CAST(UNITSTYPE AS INT) AS UNITS_TYPE_ID,
        TRY_CAST(SUBSIDIARY AS INT) AS SUBSIDIARY_ID,
        TRY_CAST(INCOMEACCOUNT AS INT) AS INCOME_ACCOUNT_ID,
        AVERAGECOST AS AVERAGE_COST,
        COST,
        TRIM(COSTINGMETHOD) AS COSTING_METHOD,
        LASTPURCHASEPRICE AS LAST_PURCHASE_PRICE,
        SHIPPINGCOST AS SHIPPING_COST,
        TOTALVALUE AS TOTAL_VALUE,
        {% if company == 'playfly' and sourcesystem == 'netsuite' %}
            totalquantityonhand AS QUANTITY_AVAILABLE,
        {% else %}
            QUANTITYAVAILABLE AS QUANTITY_AVAILABLE,
        {% endif %}
        MAXIMUMQUANTITY AS MAXIMUM_QUANTITY,
        WEIGHT AS WEIGHT,
        CAST(
            CASE 
                WHEN ISFULFILLABLE = 'T' THEN TRUE
                WHEN ISFULFILLABLE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS IS_FULFILLABLE,
        CAST(
            CASE 
                WHEN ISINACTIVE = 'T' THEN TRUE
                WHEN ISINACTIVE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS IS_INACTIVE,
        CAST(CREATEDDATE AS TIMESTAMP_NTZ) AS CREATED_DATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned