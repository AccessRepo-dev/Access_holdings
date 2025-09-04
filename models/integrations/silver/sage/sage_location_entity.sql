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

    SELECT
    -- Primary Key
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,

    -- Core Identifiers
    TRIM(LOCATIONID) AS LOCATIONID,
    TRIM(NAME) AS NAME,
    TRIM(ENTITY) AS ENTITY,
    TRIM(SPLIT_PART(ENTITY, '--', 1)) AS ENTITY_CODE,
    TRIM(SPLIT_PART(ENTITY, '--', 2)) AS ENTITY_DESCRIPTION,
    TRIM(STATUS) AS STATUS,

    -- Accounting & Legal
    TRIM(ACCOUNTINGTYPE) AS ACCOUNTINGTYPE,
    TRIM(LEGALCOUNTRYCODE) AS LEGALCOUNTRYCODE,
    TRIM(FEDERALID) AS FEDERALID,
    TRIM(CUSTTITLE) AS CUSTTITLE,
    TRIM(OPCOUNTRY) AS OPCOUNTRY,
    TRIM(REPORTPRINTAS) AS REPORTPRINTAS,
    TRIM(TAXID) AS TAXID,

    -- Dates
    CAST(STARTOPEN AS DATE) AS STARTOPEN,
    CAST(STATUTORYREPORTINGPERIOD AS DATE) AS STATUTORYREPORTINGPERIOD,
    CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHENCREATED,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Flags
    CAST(DEFAULTPARTIALEXEMPT AS BOOLEAN) AS DEFAULTPARTIALEXEMPT,
    CAST(ENABLELEGALCONTACT AS BOOLEAN) AS ENABLELEGALCONTACT,
    CAST(ENABLELEGALCONTACT_TPAR AS BOOLEAN) AS ENABLELEGALCONTACT_TPAR,
    CAST(HAS_IE_RELATION AS BOOLEAN) AS HAS_IE_RELATION,
    CAST(ISLIMITEDENTITY AS BOOLEAN) AS ISLIMITEDENTITY,
    CAST(ISROOT AS BOOLEAN) AS ISROOT,
    CAST(PARTIALEXEMPT AS BOOLEAN) AS PARTIALEXEMPT,

    -- Misc
    TRIM(ADDRESSCOUNTRYDEFAULT) AS ADDRESSCOUNTRYDEFAULT,
    TRIM(BUSINESSDAYS) AS BUSINESSDAYS,
    TRIM(WEEKENDS) AS WEEKENDS,
    TRY_CAST(FIRSTMONTH AS INT) AS FIRSTMONTH,
    TRY_CAST(FIRSTMONTHTAX AS INT) AS FIRSTMONTHTAX,

    -- Relationships
    TRY_CAST(CREATEDBY AS INT) AS CREATEDBY,
    TRY_CAST(MODIFIEDBY AS INT) AS MODIFIEDBY,

    -- Audit
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM source_data

)

select *
from cleaned
