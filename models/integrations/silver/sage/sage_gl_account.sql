{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ACCOUNT_NO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_ACCOUNT') }}
    {% if is_incremental() %}
    where cast(WHENMODIFIED as timestamp_ntz) > (
        select coalesce(max(WHEN_MODIFIED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select

        -- Primary Key
        TRY_CAST(ACCOUNTNO AS INT) AS ACCOUNT_NO,

        -- Core Fields
        TRY_CAST(RECORDNO AS INT) AS RECORD_NO,
        TRY_CAST(CATEGORYKEY AS INT) AS CATEGORY_KEY,
        TRY_CAST(CLOSETOACCTKEY AS INT) AS CLOSE_TO_ACCTKEY,
        TRIM(ALTERNATIVEACCOUNT) AS ALTERNATIVE_ACCOUNT,

        -- Descriptions
        TRIM(TITLE) AS TITLE,
        COALESCE(TRIM(CLOSINGACCOUNTTITLE), 'UNKNOWN') AS CLOSING_ACCOUNT_TITLE,
        COALESCE(TRIM(CATEGORY), 'UNKNOWN') AS CATEGORY,

        -- Account Metadata
        TRIM(ACCOUNTTYPE) AS ACCOUNT_TYPE,
        TRIM(STATUS) AS STATUS,
        TRIM(CLOSINGTYPE) AS CLOSING_TYPE,
        TRIM(NORMALBALANCE) AS NORMAL_BALANCE,

        -- Booleans / Flags
        CAST(TAXABLE AS BOOLEAN) AS TAXABLE,
        CAST(ENABLE_GLMATCHING AS BOOLEAN) AS ENABLE_GLMATCHING,
        CAST(SUBLEDGERCONTROLON AS BOOLEAN) AS SUBLEDGER_CONTROL_ON,

        -- Dimension Requirements
        CAST(REQUIREEMPLOYEE AS BOOLEAN) AS REQUIRE_EMPLOYEE,
        CAST(REQUIRECUSTOMER AS BOOLEAN) AS REQUIRE_CUSTOMER,
        CAST(REQUIREITEM AS BOOLEAN) AS REQUIRE_ITEM,
        CAST(REQUIRELOC AS BOOLEAN) AS REQUIRE_LOC,
        CAST(REQUIREVENDOR AS BOOLEAN) AS REQUIRE_VENDOR,
        CAST(REQUIREDEPT AS BOOLEAN) AS REQUIRE_DEPT,
        CAST(REQUIRECLASS AS BOOLEAN) AS REQUIRE_CLASS,
        CAST(REQUIREWAREHOUSE AS BOOLEAN) AS REQUIRE_WAREHOUSE,
        CAST(REQUIREGLDIMREVENUE_CENTER AS BOOLEAN) AS REQUIREGL_DIM_REVENUE_CENTER,
        CAST(REQUIREPROJECT AS BOOLEAN) AS REQUIRE_PROJECT,

        -- Dates
        CAST(WHENCREATED AS TIMESTAMP_NTZ) AS CREATED_DATE,
        CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHEN_MODIFIED,

        -- Relationships
        TRY_CAST(CREATEDBY AS INT) AS CREATED_BY,
        TRIM(CREATEDBYLOGINID) AS CREATED_BY_LOGIN_ID,
        TRY_CAST(MODIFIEDBY AS INT) AS MODIFIED_BY,
        TRIM(MODIFIEDBYLOGINID) AS MODIFIED_BY_LOGIN_ID,

        -- Fivetran & Audit
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

    from source_data
)

select *
from cleaned
