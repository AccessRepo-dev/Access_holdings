{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    unique_key = 'RECORDNO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_ACCT_GRP') }}
     {% if is_incremental() %}
    where cast(WHENMODIFIED as timestamp_ntz) > (
        select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        -- Primary Key
        TRY_CAST(RECORDNO AS INT) AS RECORDNO,

        -- Foreign Keys
        TRY_CAST(CLASSDIMKEY AS INT) AS CLASSDIMKEY,
        TRY_CAST(CUSTOMERID AS INT) AS CUSTOMERID,

        -- Core Identifiers
        TRIM(ACCTGROUPMANAGER) AS ACCTGROUPMANAGER,
        TRIM(ASOF) AS ASOF,
        TRIM(CLASSID) AS CLASSID,
        TRIM(CLASSNAME) AS CLASSNAME,
        TRY_CAST(CREATEDBY AS INT) AS CREATEDBY,
        TRIM(CREATEDBYLOGINID) AS CREATEDBYLOGINID,
        TRY_CAST(CUSTOMERDIMKEY AS INT) AS CUSTOMERDIMKEY,
        TRIM(CUSTOMERNAME) AS CUSTOMERNAME,
        TRIM(DBCR) AS DBCR,
        TRIM(DEPTNO) AS DEPTNO,
        TRIM(FILTERCLASS) AS FILTERCLASS,
        TRIM(FILTERCUSTOMER) AS FILTERCUSTOMER,
        TRIM(FILTERDEPT) AS FILTERDEPT,
        TRIM(FILTEREMPLOYEE) AS FILTEREMPLOYEE,
        TRIM(FILTERGLDIMREVENUE_CENTER) AS FILTERGLDIMREVENUE_CENTER,
        TRIM(FILTERITEM) AS FILTERITEM,
        TRIM(FILTERLOC) AS FILTERLOC,
        TRIM(FILTERPROJECT) AS FILTERPROJECT,
        TRIM(FILTERVENDOR) AS FILTERVENDOR,
        TRIM(FILTERWAREHOUSE) AS FILTERWAREHOUSE,
        TRIM(GLACCTGRPPURPOSEID) AS GLACCTGRPPURPOSEID,
        TRY_CAST(INCLUDECHILDAMT AS BOOLEAN) AS INCLUDECHILDAMT,
        TRY_CAST(ISKPI AS BOOLEAN) AS ISKPI,
        TRIM(LOCNO) AS LOCNO,
        TRIM(MEMBERTYPE) AS MEMBERTYPE,
        TRY_CAST(MODIFIEDBY AS INT) AS MODIFIEDBY,
        TRIM(MODIFIEDBYLOGINID) AS MODIFIEDBYLOGINID,
        TRIM(NAME) AS NAME,
        TRIM(NORMAL_BALANCE) AS NORMAL_BALANCE,
        TRY_CAST(PROJECTDIMKEY AS INT) AS PROJECTDIMKEY,
        TRIM(PROJECTID) AS PROJECTID,
        TRIM(PROJECTNAME) AS PROJECTNAME,
        TRIM(RECORD_URL) AS RECORD_URL,
        TRIM(TITLE) AS TITLE,
        TRIM(TOTALTITLE) AS TOTALTITLE,
        CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHENCREATED,
        CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

        -- Audit
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

    from source_data
)
select *
from cleaned
