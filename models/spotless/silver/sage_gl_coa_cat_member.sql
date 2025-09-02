{{ config(
    materialized = 'incremental',
    unique_key = 'CATEGORY_NAME',
    incremental_strategy = 'merge'
) }}

SELECT
    -- Primary Key
    TRIM(CATEGORYNAME) AS CATEGORY_NAME,

    -- Core Identifiers
    TRY_CAST(RECORDNO AS INT) AS RECORD_NO,
    TRY_CAST(PARENTKEY AS INT) AS PARENT_KEY,
    TRY_CAST(SORTORD AS INT) AS SORT_ORDER,
    TRIM(RECORD_URL) AS RECORD_URL,

    -- Audit
    TRY_CAST(CREATEDBY AS INT) AS CREATED_BY,
    TRY_CAST(MODIFIEDBY AS INT) AS MODIFIED_BY,
    CAST(WHENCREATED AS TIMESTAMP_NTZ) AS CREATED_DATE,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHEN_MODIFIED,

    -- Silver Load Metadata
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM {{ source('spotless_sage', 'GL_COA_CAT_MEMBER') }}

{% if is_incremental() %}
WHERE WHENMODIFIED > (
    SELECT COALESCE(MAX(WHEN_MODIFIED), '1900-01-01'::TIMESTAMP_NTZ)
    FROM {{ this }}
)
{% endif %}
