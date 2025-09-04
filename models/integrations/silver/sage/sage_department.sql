{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DEPARTMENT_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'DEPARTMENT') }}
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
    UPPER(TRIM(DEPARTMENTID)) AS DEPARTMENTID,

    -- Core Identifiers
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRIM(TITLE) AS TITLE,

    -- extract the code inside parentheses (e.g., 15, 10a, 07)
    REGEXP_SUBSTR(TITLE, '^\\(([0-9]+[a-z]?)\\)', 1, 1, 'e', 1) AS DEPARTMENT_TITLE_CODE,

    -- remove the (xx) prefix entirely to get just description
    TRIM(REGEXP_REPLACE(TITLE, '^\\([0-9]+[a-z]?\\)\\s*', '')) AS DEPARTMENT_TITLE_DESCRIPTION,

    TRIM(CUSTTITLE) AS CUSTTITLE,
    TRIM(STATUS) AS STATUS,

    -- Hierarchy
    TRIM(PARENTID) AS PARENTID,
    TRY_CAST(PARENTKEY AS INT) AS PARENTKEY,
    TRIM(PARENTNAME) AS PARENTNAME,

    -- Supervisor
    TRIM(SUPERVISORID) AS SUPERVISORID,
    TRY_CAST(SUPERVISORKEY AS INT) AS SUPERVISORKEY,
    INITCAP(TRIM(SUPERVISORNAME)) AS SUPERVISORNAME,

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
FROM source_data

)

select *
from cleaned
