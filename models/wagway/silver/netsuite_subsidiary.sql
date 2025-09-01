{{ config(
    materialized = 'incremental',
    unique_key = 'SUBSIDIARY_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    CAST(currency AS INT) AS CURRENCY_ID,
    fullname AS SUBSIDIARY_FULL_NAME,
    isinactive AS IS_INACTIVE,
    name AS SUBSIDIARY_NAME,
    CAST(parent AS INT) AS PARENT_ID,
    CAST(id AS INT) AS SUBSIDIARY_ID,
    CURRENT_TIMESTAMP()::TIMESTAMP AS SILVER_LOAD_DATE
FROM {{ source('wagway_netsuite', 'SUBSIDIARY') }}
