{{ config(
    materialized = 'incremental',
    unique_key = 'CURRENCY_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    -- Primary Key
    TRY_CAST(ID AS INT) AS CURRENCY_ID,

    -- Core Info
    TRIM(CURRENCY_NAME) AS CURRENCY_NAME,
    TRIM(NAME) AS NAME,
    TRIM(SYMBOL) AS SYMBOL,

    -- Audit Info
    TRY_CAST(CREATED_BY AS INT) AS CREATED_BY,
    TRY_CAST(UPDATED_BY AS INT) AS UPDATED_BY,
    TRY_CAST(CREATED_AT AS TIMESTAMP_NTZ) AS CREATED_AT,
    TRY_CAST(UPDATED_AT AS TIMESTAMP_NTZ) AS UPDATED_AT,

    -- Fivetran
    _FIVETRAN_DELETED AS IS_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM {{ source('spotless_sage', 'CURRENCY') }}

{% if is_incremental() %}
WHERE UPDATED_AT > (
    SELECT COALESCE(MAX(UPDATED_AT), '1900-01-01'::TIMESTAMP_NTZ)
    FROM {{ this }}
)
{% endif %}
