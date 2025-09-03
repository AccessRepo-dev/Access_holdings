{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'LOCATION_ID'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'LOCATION') }}
    
    {% if is_incremental() %}
        where WHENMODIFIED > (
            select coalesce(max(WHEN_MODIFIED), '1900-01-01'::timestamp_ntz)
            from {{ this }}
        )
        or _FIVETRAN_DELETED = true
    {% endif %}

),

cleaned as (

    select
        -- Primary Key
        TRIM(LOCATIONID) AS LOCATION_ID,

        -- Core Identifiers
        TRY_CAST(RECORDNO AS INT) AS RECORD_NO,
        TRIM(NAME) AS LOCATION_NAME,
        TRIM(ENTITY) AS ENTITY,
        TRIM(STATUS) AS STATUS,
        TRIM(LOCATIONTYPE) AS LOCATION_TYPE,
        TRIM(MODEL_TYPE) AS MODEL_TYPE,
        TRIM(PROJECT_TYPE) AS PROJECT_TYPE,
        TRIM(SITE_TYPE) AS SITE_TYPE,
        TRIM(SITE_STATUS) AS SITE_STATUS,
        TRIM(STAGE) AS STAGE,
        TRIM(REVENUE_STREAM) AS REVENUE_STREAM,
        TRY_CAST(SORT_ORDER AS INT) AS SORT_ORDER,

        -- Contact Info
        TRIM(CONTACTINFO_CONTACTNAME) AS CONTACT_NAME,
        TRIM(CONTACTINFO_FIRSTNAME) AS CONTACT_FIRST_NAME,
        TRIM(CONTACTINFO_LASTNAME) AS CONTACT_LAST_NAME,
        TRIM(CONTACTINFO_PRINTAS) AS CONTACT_PRINT_AS,
        TRY_CAST(CONTACTKEY AS INT) AS CONTACT_KEY,

        -- Contact Address
        TRIM(CONTACTINFO_MAILADDRESS_ADDRESS_1) AS CONTACT_ADDRESS_1,
        TRIM(CONTACTINFO_MAILADDRESS_CITY) AS CONTACT_CITY,
        TRIM(CONTACTINFO_MAILADDRESS_STATE) AS CONTACT_STATE,
        TRIM(CONTACTINFO_MAILADDRESS_COUNTRY) AS CONTACT_COUNTRY,
        TRIM(CONTACTINFO_MAILADDRESS_COUNTRYCODE) AS CONTACT_COUNTRY_CODE,
        TRIM(CONTACTINFO_MAILADDRESS_ZIP) AS CONTACT_ZIP,  -- keep as text (safer than int)

        -- Accounting & Legal
        TRIM(FEDERALID) AS FEDERAL_ID,
        TRIM(CUSTTITLE) AS CUSTOMER_TITLE,
        TRIM(REPORTPRINTAS) AS REPORT_PRINT_AS,
        TRIM(TAXID) AS TAX_ID,

        -- Dates
        CAST(CLOSE_DATE AS DATE) AS CLOSE_DATE,
        CAST(STARTDATE AS DATE) AS START_DATE,
        CAST(LOCATION_OPEN_DATE AS DATE) AS LOCATION_OPEN_DATE,
        CAST(LOCATION_COHORT_OPEN_DATE AS DATE) AS LOCATION_COHORT_OPEN_DATE,
        CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHEN_CREATED,
        CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHEN_MODIFIED,

        -- Flags
        CAST(HAS_IE_RELATION AS BOOLEAN) AS HAS_IE_RELATION,
        CAST(ISROOT AS BOOLEAN) AS IS_ROOT,

        -- Misc
        TRIM(ADDRESSCOUNTRYDEFAULT) AS ADDRESS_COUNTRY_DEFAULT,
        TRIM(BUSINESSDAYS) AS BUSINESS_DAYS,
        TRIM(WEEKENDS) AS WEEKENDS,
        TRIM(DISTRICT_MANAGER) AS DISTRICT_MANAGER,
        TRIM(CPM) AS CPM,
        TRY_CAST(FIRSTMONTH AS INT) AS FIRST_MONTH,
        TRY_CAST(FIRSTMONTHTAX AS INT) AS FIRST_MONTH_TAX,

        -- Relationships
        TRIM(PARENTID) AS PARENT_ID,
        TRIM(PARENTNAME) AS PARENT_NAME,
        TRY_CAST(PARENTKEY AS INT) AS PARENT_KEY,
        TRY_CAST(CREATEDBY AS INT) AS CREATED_BY,
        TRY_CAST(MODIFIEDBY AS INT) AS MODIFIED_BY,
        TRIM(CREATEDBYLOGINID) AS CREATED_BY_LOGIN_ID,
        TRIM(MODIFIEDBYLOGINID) AS MODIFIED_BY_LOGIN_ID,

        -- Audit
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

    from source_data
)

select * from cleaned
