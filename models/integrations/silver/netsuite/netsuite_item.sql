{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'ITEM') }}
    {% if is_incremental() %}
    where 
        cast(LASTMODIFIEDDATE as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(ID AS INT) AS ID,
        TRIM(ITEMID) AS ITEMID,
        TRIM(DISPLAYNAME) AS DISPLAYNAME,
        TRIM(FULLNAME) AS FULLNAME,
        TRIM(DESCRIPTION) AS DESCRIPTION,
        TRIM(STOCKDESCRIPTION) AS STOCKDESCRIPTION,
        TRIM(ITEMTYPE) AS ITEMTYPE,
        TRIM(SUBTYPE) AS SUBTYPE,
        TRIM(MANUFACTURER) AS MANUFACTURER,
        TRIM(VENDORNAME) AS VENDORNAME,
        TRY_CAST(CLASS AS INT) AS CLASS,
        TRY_CAST(DEPARTMENT AS INT) AS DEPARTMENT,
        TRY_CAST(LOCATION AS INT) AS LOCATION,
        TRY_CAST(PARENT AS INT) AS PARENT,
        TRY_CAST(PRICINGGROUP AS INT) AS PRICINGGROUP,
        TRY_CAST(SALEUNIT AS INT) AS SALEUNIT,
        TRY_CAST(STOCKUNIT AS INT) AS STOCKUNIT,
        TRY_CAST(UNITSTYPE AS INT) AS UNITSTYPE,
        TRY_CAST(SUBSIDIARY AS INT) AS SUBSIDIARY,
        TRY_CAST(INCOMEACCOUNT AS INT) AS INCOMEACCOUNT,
        AVERAGECOST AS AVERAGECOST,
        COST AS COST,
        TRIM(COSTINGMETHOD) AS COSTINGMETHOD,
        LASTPURCHASEPRICE AS LASTPURCHASEPRICE,
        SHIPPINGCOST AS SHIPPINGCOST,
        TOTALVALUE AS TOTALVALUE,
        {% if company == 'playfly' and sourcesystem == 'netsuite' %}
            TOTALQUANTITYONHAND AS QUANTITYAVAILABLE,
        {% else %}
            QUANTITYAVAILABLE AS QUANTITYAVAILABLE,
        {% endif %}
        MAXIMUMQUANTITY AS MAXIMUMQUANTITY,
        WEIGHT AS WEIGHT,
        CAST(
            CASE 
                WHEN ISFULFILLABLE = 'T' THEN TRUE
                WHEN ISFULFILLABLE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS ISFULFILLABLE,
        CASE 
            WHEN ISINACTIVE = 'T' THEN TRUE
            WHEN ISINACTIVE = 'F' THEN FALSE
            ELSE NULL
        END AS ISINACTIVE,
        CAST(CREATEDDATE AS TIMESTAMP_NTZ) AS CREATEDDATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LASTMODIFIEDDATE,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned
