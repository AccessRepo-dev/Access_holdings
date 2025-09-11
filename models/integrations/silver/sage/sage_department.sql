{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'DEPARTMENT') }}
    {% if is_incremental() %}
    where CAST(WHENMODIFIED AS TIMESTAMP_NTZ) > (
        select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    SELECT
    -- Primary Key
    UPPER(TRIM(DEPARTMENTID)) AS DEPARTMENTID,

    -- Core Identifiers
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRIM(TITLE) AS TITLE,

    TRIM(STATUS) AS STATUS,

    -- Hierarchy
    TRIM(PARENTID) AS PARENTID,
    TRY_CAST(PARENTKEY AS INT) AS PARENTKEY,
    TRIM(PARENTNAME) AS PARENTNAME,

    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Flags / Deletes
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,

    -- Audit
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
FROM source_data

)

select *
from cleaned
