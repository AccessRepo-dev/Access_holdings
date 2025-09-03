{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}

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
    select
        -- Primary Key
        UPPER(TRIM(DEPARTMENTID)) AS DEPARTMENT_ID,

        -- Core Identifiers
        TRY_CAST(RECORDNO AS INT) AS RECORD_NO,
        TRIM(TITLE) AS DEPARTMENT_TITLE,

        -- extract the code inside parentheses (e.g., 15, 10a, 07)
        REGEXP_SUBSTR(TITLE, '^\\(([0-9]+[a-z]?)\\)', 1, 1, 'e', 1) AS DEPARTMENT_TITLE_CODE,

        -- remove the (xx) prefix entirely to get just description
        TRIM(REGEXP_REPLACE(TITLE, '^\\([0-9]+[a-z]?\\)\\s*', '')) AS DEPARTMENT_TITLE_DESCRIPTION,

        TRIM(CUSTTITLE) AS CUSTOM_TITLE,
        TRIM(STATUS) AS STATUS,

        -- Hierarchy
        TRIM(PARENTID) AS PARENT_ID,
        TRY_CAST(PARENTKEY AS INT) AS PARENT_KEY,
        TRIM(PARENTNAME) AS PARENT_NAME,

        -- Supervisor
        TRIM(SUPERVISORID) AS SUPERVISOR_ID,
        TRY_CAST(SUPERVISORKEY AS INT) AS SUPERVISOR_KEY,
        INITCAP(TRIM(SUPERVISORNAME)) AS SUPERVISOR_NAME,

        -- Relationships
        TRY_CAST(CREATEDBY AS INT) AS CREATED_BY,
        TRY_CAST(MODIFIEDBY AS INT) AS MODIFIED_BY,

        -- Dates
        CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHEN_CREATED,
        CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHEN_MODIFIED,

        -- Flags / Deletes
        _FIVETRAN_DELETED AS IS_DELETED,

        -- Audit
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select *
from cleaned
