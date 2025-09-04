{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'CLASS_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'CLASS') }}
    {% if is_incremental() %}
    where CAST(WHENMODIFIED AS TIMESTAMP_NTZ) > (
        select coalesce(max(WHEN_MODIFIED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    SELECT
    -- Primary Key
    UPPER(TRIM(CLASSID)) AS CLASSID,

    -- Core Identifiers
    TRIM(NAME) AS NAME,
    REGEXP_SUBSTR(NAME, '^\\(([0-9]+[a-z]?)\\)', 1, 1, 'e', 1) AS CLASS_NAME_CODE,
    TRIM(REGEXP_REPLACE(NAME, '^\\([0-9]+[a-z]?\\)\\s*', '')) AS CLASS_NAME_DESCRIPTION,
    TRIM(STATUS) AS STATUS,
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,

    -- Parent / Hierarchy
    TRIM(PARENTID) AS PARENTID,
    TRY_CAST(PARENTKEY AS INT) AS PARENTKEY,

    -- Attributes
    TRIM(CA_LIMIT_CHECKBOX) AS CA_LIMIT_CHECKBOX,
    TRIM(CA_LIMIT_DESCRIPTION) AS CA_LIMIT_DESCRIPTION,

    -- Relationships
    TRY_CAST(CREATEDBY AS INT) AS CREATEDBY,
    TRY_CAST(MODIFIEDBY AS INT) AS MODIFIEDBY,

    -- Dates
    CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHENCREATED,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Flags / Deletes
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,

    -- Audit
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
FROM source_data;

)

select *
from cleaned
