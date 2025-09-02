{{ config(
    materialized = 'incremental',
    unique_key = 'ENTITY_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    -- Primary Key
    UPPER(TRIM(ENTITYID)) AS ENTITY_ID,

    -- Core Identifiers
    TRIM(ENTITYSTATUS) AS ENTITY_STATUS,
    TRY_CAST(RECORDNO AS INT) AS RECORD_NO,

    -- Audit
    _FIVETRAN_DELETED AS IS_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM {{ source('spotless_sage', 'ENTITYACCTDEFAULT') }}

{% if is_incremental() %}
WHERE RECORDNO > (
    SELECT COALESCE(MAX(RECORD_NO), 0)
    FROM {{ this }}
)
{% endif %}