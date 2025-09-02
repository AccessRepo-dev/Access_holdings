{{ config(
    materialized = 'incremental',
    unique_key = 'CLASS_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    -- Primary Key
    UPPER(TRIM(CLASSID)) AS CLASS_ID,

    -- Core Identifiers
    TRIM(NAME) AS CLASS_NAME,
    -- Extract code inside parentheses, e.g. (15), (10a)
    REGEXP_SUBSTR(NAME, '^\\(([0-9]+[a-z]?)\\)', 1, 1, 'e', 1) AS CLASS_NAME_CODE,

    -- remove the (xx) prefix entirely to get just description
    TRIM(REGEXP_REPLACE(NAME, '^\\([0-9]+[a-z]?\\)\\s*', '')) AS CLASS_NAME_DESCRIPTION,
    TRIM(STATUS) AS STATUS,
    TRY_CAST(RECORDNO AS INT) AS RECORD_NO,
    
    -- Parent / Hierarchy
    TRIM(PARENTID) AS PARENT_ID,
    TRY_CAST(PARENTKEY AS INT) AS PARENT_KEY,

    -- Attributes
    TRIM(CA_LIMIT_CHECKBOX) AS CA_LIMIT_CHECKBOX,
    TRIM(CA_LIMIT_DESCRIPTION) AS CA_LIMIT_DESCRIPTION,

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

FROM {{ source('spotless_sage', 'CLASS') }}

{% if is_incremental() %}
WHERE WHENMODIFIED > (
    SELECT COALESCE(MAX(WHEN_MODIFIED), '1900-01-01'::TIMESTAMP_NTZ)
    FROM {{ this }}
)
{% endif %}
