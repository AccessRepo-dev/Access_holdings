{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'EMPLOYEE_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'EMPLOYEE') }}
    {% if is_incremental() %}
    where CAST(WHENMODIFIED AS TIMESTAMP_NTZ) > (
        select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        -- Primary Key
        UPPER(TRIM(EMPLOYEEID)) AS EMPLOYEE_ID,

        -- Core Identifiers
        TRY_CAST(RECORDNO AS INT) AS RECORD_NO,
        TRIM(STATUS) AS STATUS,
        TRIM(TITLE) AS TITLE,

        -- Contact Info
        INITCAP(TRIM(CONTACT_NAME)) AS CONTACT_NAME,
        TRY_CAST(CONTACTKEY AS INT) AS CONTACT_KEY,

        -- Personal Info
        TRIM(PERSONALINFO_COMPANYNAME) AS PERSONAL_INFO_COMPANY_NAME,
        TRIM(PERSONALINFO_CONTACTNAME) AS PERSONAL_INFO_CONTACT_NAME,

        -- Supervisor
        TRIM(SUPERVISORID) AS SUPERVISOR_ID,
        INITCAP(TRIM(SUPERVISORNAME)) AS SUPERVISOR_NAME,

        -- Name & Contact
        TRIM(PERSONALINFO_FIRSTNAME) AS PERSONAL_INFO_FIRST_NAME,
        TRIM(PERSONALINFO_LASTNAME) AS PERSONAL_INFO_LAST_NAME,
        TRIM(PERSONALINFO_INITIAL) AS PERSONAL_INFO_INITIAL,
        TRIM(PERSONALINFO_EMAIL_1) AS PERSONAL_INFO_EMAIL,
        TRIM(PERSONALINFO_PHONE_1) AS PERSONAL_INFO_PHONE,
        TRIM(PERSONALINFO_PRINTAS) AS PERSONAL_INFO_PRINT_AS,
        TRIM(PERSONALINFO_MAILADDRESS_COUNTRY) AS PERSONAL_INFO_COUNTRY,
        TRIM(PERSONALINFO_MAILADDRESS_COUNTRYCODE) AS PERSONAL_INFO_COUNTRY_CODE,

        -- Department
        TRIM(DEPARTMENTID) AS DEPARTMENT_ID,
        TRY_CAST(DEPARTMENTKEY AS INT) AS DEPARTMENT_KEY,

        -- Location
        TRIM(LOCATIONID) AS LOCATION_ID,
        TRY_CAST(LOCATIONKEY AS INT) AS LOCATION_KEY,

        -- Employee Type
        TRIM(EMPLOYEETYPE) AS EMPLOYEE_TYPE,
        TRY_CAST(EMPTYPEKEY AS INT) AS EMPLOYEE_TYPE_KEY,

        -- Entity
        TRIM(ENTITY) AS ENTITY,
        TRIM(MEGAENTITYID) AS MEGA_ENTITY_ID,
        TRY_CAST(MEGAENTITYKEY AS INT) AS MEGA_ENTITY_KEY,
        TRIM(MEGAENTITYNAME) AS MEGA_ENTITY_NAME,

        -- Flags
        CAST(GENERIC AS BOOLEAN) AS IS_GENERIC,
        CAST(MERGEPAYMENTREQ AS BOOLEAN) AS MERGE_PAYMENT_REQUIRED,
        CAST(PAYMENTNOTIFY AS BOOLEAN) AS PAYMENT_NOTIFY,
        CAST(POSTACTUALCOST AS BOOLEAN) AS POST_ACTUAL_COST,

        -- Relationships
        TRY_CAST(CREATEDBY AS INT) AS CREATED_BY,
        TRY_CAST(MODIFIEDBY AS INT) AS MODIFIED_BY,
        TRY_CAST(PARENTKEY AS INT) AS PARENT_KEY,

        -- Services
        TRIM(FILEPAYMENTSERVICE) AS FILE_PAYMENT_SERVICE,

        -- Dates
        CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHEN_CREATED,
        CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHEN_MODIFIED,

        -- Audit
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

    from source_data
)

select *
from cleaned
