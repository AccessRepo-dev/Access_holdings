{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

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
    SELECT
    -- Primary Key
    TRY_CAST(ACCOUNTNO AS INT) AS ACCOUNTNO,

    -- Core Fields
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRY_CAST(CATEGORYKEY AS INT) AS CATEGORYKEY,
    TRY_CAST(CLOSETOACCTKEY AS INT) AS CLOSETOACCTKEY,
    TRIM(ALTERNATIVEACCOUNT) AS ALTERNATIVEACCOUNT,

    -- Descriptions
    TRIM(TITLE) AS TITLE,
    COALESCE(TRIM(CLOSINGACCOUNTTITLE), 'UNKNOWN') AS CLOSINGACCOUNTTITLE,
    COALESCE(TRIM(CATEGORY), 'UNKNOWN') AS CATEGORY,

    -- Account Metadata
    TRIM(ACCOUNTTYPE) AS ACCOUNTTYPE,
    TRIM(STATUS) AS STATUS,
    TRIM(CLOSINGTYPE) AS CLOSINGTYPE,
    TRIM(NORMALBALANCE) AS NORMALBALANCE,

    -- Booleans / Flags
    CAST(TAXABLE AS BOOLEAN) AS TAXABLE,
    CAST(ENABLE_GLMATCHING AS BOOLEAN) AS ENABLE_GLMATCHING,
    CAST(SUBLEDGERCONTROLON AS BOOLEAN) AS SUBLEDGERCONTROLON,

    -- Dimension Requirements
    CAST(REQUIREEMPLOYEE AS BOOLEAN) AS REQUIREEMPLOYEE,
    CAST(REQUIRECUSTOMER AS BOOLEAN) AS REQUIRECUSTOMER,
    CAST(REQUIREITEM AS BOOLEAN) AS REQUIREITEM,
    CAST(REQUIRELOC AS BOOLEAN) AS REQUIRELOC,
    CAST(REQUIREVENDOR AS BOOLEAN) AS REQUIREVENDOR,
    CAST(REQUIREDEPT AS BOOLEAN) AS REQUIREDEPT,
    CAST(REQUIRECLASS AS BOOLEAN) AS REQUIRECLASS,
    CAST(REQUIREWAREHOUSE AS BOOLEAN) AS REQUIREWAREHOUSE,
    CAST(REQUIREGLDIMREVENUE_CENTER AS BOOLEAN) AS REQUIREGLDIMREVENUE_CENTER,
    CAST(REQUIREPROJECT AS BOOLEAN) AS REQUIREPROJECT,

    -- Dates
    CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHENCREATED,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Relationships
    TRY_CAST(CREATEDBY AS INT) AS CREATEDBY,
    TRIM(CREATEDBYLOGINID) AS CREATEDBYLOGINID,
    TRY_CAST(MODIFIEDBY AS INT) AS MODIFIEDBY,
    TRIM(MODIFIEDBYLOGINID) AS MODIFIEDBYLOGINID,

    -- Fivetran & Audit
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
FROM source_data;

)

select *
from cleaned
