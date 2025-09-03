{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'RECORD_NO'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_ENTRY') }}

    {% if is_incremental() %}
        where WHENCREATED > (
            select coalesce(max(WHEN_MODIFIED), '1900-01-01'::timestamp_ntz)
            from {{ this }}
        )
    {% endif %}

),

cleaned as (

    select
        -- Primary Key
        try_cast(RECORDNO as int) as RECORD_NO,

        -- Foreign Keys & Identifiers
        try_cast(ACCOUNTKEY as int) as ACCOUNT_KEY,
        trim(ACCOUNTNO) as ACCOUNT_NO,
        trim(ACCOUNTTITLE) as ACCOUNT_TITLE,
        try_cast(BATCH_NUMBER as int) as BATCH_NUMBER,
        trim(BATCHNO) as BATCH_NO,
        trim(BATCHTITLE) as BATCH_TITLE,
        try_cast(CLASSDIMKEY as int) as CLASS_DIM_KEY,
        trim(CLASSID) as CLASS_ID,
        trim(CLASSNAME) as CLASS_NAME,
        try_cast(DEPARTMENTKEY as int) as DEPARTMENT_KEY,
        trim(DEPARTMENT) as DEPARTMENT,
        trim(DEPARTMENTTITLE) as DEPARTMENT_TITLE,
        try_cast(ITEMDIMKEY as int) as ITEM_DIM_KEY,
        trim(ITEMID) as ITEM_ID,
        trim(ITEMNAME) as ITEM_NAME,
        try_cast(PROJECTDIMKEY as int) as PROJECT_DIM_KEY,
        trim(PROJECTID) as PROJECT_ID,
        trim(PROJECTNAME) as PROJECT_NAME,
        trim(LOCATION) as LOCATION,
        try_cast(LOCATIONKEY as int) as LOCATION_KEY,
        trim(LOCATIONNAME) as LOCATION_NAME,
        try_cast(VENDORDIMKEY as int) as VENDOR_DIM_KEY,
        try_cast(VENDORID as int) as VENDOR_ID,
        trim(VENDORNAME) as VENDOR_NAME,
        try_cast(WAREHOUSEDIMKEY as int) as WAREHOUSE_DIM_KEY,
        trim(WAREHOUSEID) as WAREHOUSE_ID,
        trim(WAREHOUSENAME) as WAREHOUSE_NAME,

        -- Core Attributes
        trim(DESCRIPTION) as DESCRIPTION,
        trim(DOCUMENT) as DOCUMENT,
        trim(STATE) as STATE,
        ADJ as IS_ADJ,
        BILLABLE as IS_BILLABLE,
        STATISTICAL as IS_STATISTICAL,
        try_cast(LINE_NO as int) as LINE_NO,
        try_cast(TR_TYPE as int) as TR_TYPE,

        -- Amounts, Currency & Exchange
        AMOUNT,
        TRX_AMOUNT, 
        trim(CURRENCY) as CURRENCY,
        trim(BASECURR) as BASE_CURRENCY,
        try_cast(EXCHANGE_RATE as int) as EXCHANGE_RATE,
        try_cast(EXCH_RATE_TYPE_ID as int) as EXCH_RATE_TYPE_ID,
        cast(EXCH_RATE_DATE as date) as EXCH_RATE_DATE,
        try_cast(GLDIMREVENUE_CENTER as int) as GL_DIM_REVENUE_CENTER,

        -- Dates
        cast(BATCH_DATE as date) as BATCH_DATE,
        cast(ENTRY_DATE as date) as ENTRY_DATE,
        cast(CLRDATE as date) as CLR_DATE,
        cast(WHENCREATED as timestamp_ntz) as WHEN_CREATED,
        cast(WHENMODIFIED as timestamp_ntz) as WHEN_MODIFIED,

        -- Audit
        try_cast(CREATEDBY as int) as CREATED_BY,
        trim(CREATEDBYLOGINID) as CREATED_BY_LOGIN_ID,
        try_cast(MODIFIEDBY as int) as MODIFIED_BY,
        trim(MODIFIEDBYLOGINID) as MODIFIED_BY_LOGIN_ID,
        try_cast(USERNO as int) as USER_NO,

        -- Metadata
        trim(RECORD_URL) as RECORD_URL,
        try_cast(RDEPRECIATION_SUMMARY as int) as R_DEPRECIATION_SUMMARY,

        -- Silver Load Metadata
        current_timestamp()::timestamp_ntz as SILVER_LOAD_DATE

    from source_data
)

select *
from cleaned
