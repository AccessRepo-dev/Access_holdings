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
    from {{ get_raw_source(company, sourcesystem, 'LOCATION_ENTITY') }}

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
        try_cast(RECORDNO as int) as RECORD_NO,

        -- Core Identifiers
        trim(LOCATIONID) as LOCATION_ID,
        trim(NAME) as LOCATION_NAME,
        trim(ENTITY) as ENTITY,
        trim(split_part(ENTITY,'--',1)) as ENTITY_CODE,
        trim(split_part(ENTITY,'--',2)) as ENTITY_DESCRIPTION,
        trim(STATUS) as STATUS,

        -- Accounting & Legal
        trim(ACCOUNTINGTYPE) as ACCOUNTING_TYPE,
        trim(LEGALCOUNTRYCODE) as LEGAL_COUNTRY_CODE,
        trim(FEDERALID) as FEDERAL_ID,
        trim(CUSTTITLE) as CUSTOMER_TITLE,
        trim(OPCOUNTRY) as OP_COUNTRY,
        trim(REPORTPRINTAS) as REPORT_PRINT_AS,
        trim(TAXID) as TAX_ID,

        -- Dates
        cast(STARTOPEN as date) as START_OPEN,
        cast(STATUTORYREPORTINGPERIOD as date) as STATUTORY_REPORTING_PERIOD,
        cast(WHENCREATED as timestamp_ntz) as WHEN_CREATED,
        cast(WHENMODIFIED as timestamp_ntz) as WHEN_MODIFIED,

        -- Flags
        cast(DEFAULTPARTIALEXEMPT as boolean) as DEFAULT_PARTIAL_EXEMPT,
        cast(ENABLELEGALCONTACT as boolean) as ENABLE_LEGAL_CONTACT,
        cast(ENABLELEGALCONTACT_TPAR as boolean) as ENABLE_LEGAL_CONTACT_TPAR,
        cast(HAS_IE_RELATION as boolean) as HAS_IE_RELATION,
        cast(ISLIMITEDENTITY as boolean) as IS_LIMITED_ENTITY,
        cast(ISROOT as boolean) as IS_ROOT,
        cast(PARTIALEXEMPT as boolean) as PARTIAL_EXEMPT,

        -- Misc
        trim(ADDRESSCOUNTRYDEFAULT) as ADDRESS_COUNTRY_DEFAULT,
        trim(BUSINESSDAYS) as BUSINESS_DAYS,
        trim(WEEKENDS) as WEEKENDS,
        try_cast(FIRSTMONTH as int) as FIRST_MONTH,
        try_cast(FIRSTMONTHTAX as int) as FIRST_MONTH_TAX,

        -- Relationships
        try_cast(CREATEDBY as int) as CREATED_BY,
        try_cast(MODIFIEDBY as int) as MODIFIED_BY,

        -- Audit
        _FIVETRAN_DELETED as IS_DELETED,
        current_timestamp()::timestamp_ntz as SILVER_LOAD_DATE

    from source_data
)

select *
from cleaned
