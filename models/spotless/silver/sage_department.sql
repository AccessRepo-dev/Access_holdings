{{ config(
    materialized = 'incremental',
    unique_key = 'DEPARTMENT_ID',
    incremental_strategy = 'merge'
) }}

SELECT
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

FROM {{ source('spotless_sage', 'DEPARTMENT') }}

{% if is_incremental() %}
WHERE WHENMODIFIED > (
    SELECT COALESCE(MAX(WHEN_MODIFIED), '1900-01-01'::TIMESTAMP_NTZ)
    FROM {{ this }}
)
{% endif %}