{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}

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
        where WHENMODIFIED > (
            select coalesce(max(WHEN_MODIFIED), '1900-01-01'::timestamp_ntz)
            from {{ this }}
        )
    {% endif %}

),

cleaned as (

    select
        -- Primary Key
        trim(ITEMID) as ITEM_ID,

        -- Core Identifiers
        try_cast(RECORDNO as int) as RECORD_NO,
        trim(NAME) as ITEM_NAME,
        trim(ITEMTYPE) as ITEM_TYPE,
        trim(PRODUCTTYPE) as PRODUCT_TYPE,
        trim(PRODUCTLINEID) as PRODUCT_LINE_ID,
        try_cast(PRODUCTLINERECORDNO as int) as PRODUCT_LINE_RECORD_NO,
        trim(STATUS) as STATUS,

        -- Flags
        cast(ALLOW_BACKORDER as boolean) as ALLOW_BACKORDER,
        cast(ALLOWMULTIPLETAXGRPS as boolean) as ALLOW_MULTIPLE_TAX_GROUPS,
        cast(AUTOPRINTLABEL as boolean) as AUTO_PRINT_LABEL,
        cast(BUYTOORDER as boolean) as BUY_TO_ORDER,
        cast(CNDEFAULTBUNDLE as boolean) as CN_DEFAULT_BUNDLE,
        cast(COMPLIANTITEM as boolean) as COMPLIANT_ITEM,
        cast(COMPUTEFORSHORTTERM as boolean) as COMPUTE_FOR_SHORT_TERM,
        cast(CONTRACTENABLED as boolean) as CONTRACT_ENABLED,
        cast(DROPSHIP as boolean) as DROP_SHIP,
        cast(ENABLE_REPLENISHMENT as boolean) as ENABLE_REPLENISHMENT,
        cast(ENABLEFULFILLMENT as boolean) as ENABLE_FULFILLMENT,
        cast(ENABLELANDEDCOST as boolean) as ENABLE_LANDED_COST,
        cast(ENGINEERINGAPPROVAL as boolean) as ENGINEERING_APPROVAL,
        cast(GIFTCARD as boolean) as GIFT_CARD,
        cast(HASSTARTENDDATES as boolean) as HAS_START_END_DATES,
        cast(ISSUPPLYITEM as boolean) as IS_SUPPLY_ITEM,
        cast(MRR as boolean) as MRR,
        cast(QUALITYCONTROLAPPROVAL as boolean) as QUALITY_CONTROL_APPROVAL,
        cast(RESTRICTEDITEM as boolean) as RESTRICTED_ITEM,
        cast(SAFETYITEM as boolean) as SAFETY_ITEM,
        cast(SALESAPPROVAL as boolean) as SALES_APPROVAL,
        cast(TAXABLE as boolean) as TAXABLE,
        cast(WEBENABLED as boolean) as WEB_ENABLED,

        -- Financials / Pricing
        BASEPRICE as BASE_PRICE,
        trim(BASEUOM) as BASE_UOM,
        trim(COST_METHOD) as COST_METHOD,
        trim(GLGROUP) as GL_GROUP,
        try_cast(GLGRPKEY as int) as GL_GROUP_KEY,
        STANDARD_COST as STANDARD_COST,
        IONHAND as INVENTORY_ON_HAND,
        try_cast(IONORDER as int) as INVENTORY_ON_ORDER,
        IUNCOMMITTED as INVENTORY_UNCOMMITTED,
        try_cast(MAX_ORDER_QTY as int) as MAX_ORDER_QTY,
        try_cast(REORDER_POINT as int) as REORDER_POINT,
        try_cast(REORDER_QTY as int) as REORDER_QTY,
        try_cast(SAFETY_STOCK as int) as SAFETY_STOCK,
        trim(REPLENISHMENT_METHOD) as REPLENISHMENT_METHOD,
        trim(DEFAULT_CONVERSIONTYPE) as DEFAULT_CONVERSION_TYPE,
        trim(DEFAULT_REPLENISHMENT_UOM) as DEFAULT_REPLENISHMENT_UOM,

        -- Rev Rec & Contract
        try_cast(DEFAULTREVRECTEMPLKEY as int) as DEFAULT_REV_REC_TEMPLATE_KEY,
        trim(DEFCONTRACTDEFERRALSTATUS) as DEF_CONTRACT_DEFERRAL_STATUS,
        trim(DEFCONTRACTDELIVERYSTATUS) as DEF_CONTRACT_DELIVERY_STATUS,
        try_cast(DEFERREDREVACCTKEY as int) as DEFERRED_REV_ACCT_KEY,
        trim(REVPRINTING) as REV_PRINTING,
        trim(VSOECATEGORY) as VSOE_CATEGORY,
        trim(VSOEDLVRSTATUS) as VSOE_DELIVERY_STATUS,
        trim(VSOEREVDEFSTATUS) as VSOE_REV_DEF_STATUS,

        -- Units of Measure
        trim(UOM_INVUOMDETAIL_UNIT) as UOM_INV_UNIT,
        try_cast(UOM_POUOMDETAIL_CONVFACTOR as int) as UOM_PO_CONV_FACTOR,
        trim(UOM_POUOMDETAIL_UNIT) as UOM_PO_UNIT,
        try_cast(UOM_SOUOMDETAIL_CONVFACTOR as int) as UOM_SO_CONV_FACTOR,
        trim(UOM_SOUOMDETAIL_UNIT) as UOM_SO_UNIT,
        trim(UOMGRP) as UOM_GROUP,
        try_cast(UOMGRPKEY as int) as UOM_GROUP_KEY,

        -- Extra
        trim(EXTENDED_DESCRIPTION) as EXTENDED_DESCRIPTION,
        trim(NOTE) as NOTE,

        -- Relationships
        try_cast(CREATEDBY as int) as CREATED_BY,
        try_cast(MODIFIEDBY as int) as MODIFIED_BY,

        -- Dates
        cast(WHENCREATED as timestamp_ntz) as WHEN_CREATED,
        cast(WHENMODIFIED as timestamp_ntz) as WHEN_MODIFIED,
        cast(WHENLASTSOLD as date) as WHEN_LAST_SOLD,
        cast(WHENLASTRECEIVED as date) as WHEN_LAST_RECEIVED,

        -- Audit
        _FIVETRAN_DELETED as IS_DELETED,
        current_timestamp()::timestamp_ntz as SILVER_LOAD_DATE

    from source_data
)

select *
from cleaned
