{{ config(
    materialized = 'incremental',
    unique_key = 'CLASS_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    FULLNAME AS CLASS_FULL_NAME,
    CAST(ID AS INT) AS CLASS_ID,
    ISINACTIVE AS IS_INACTIVE,
    CAST(LASTMODIFIEDDATE AS DATE) AS LAST_MODIFIED_DATE,
    NAME AS CLASS_NAME,
    CAST(PARENT AS INT) AS PARENT,
    CURRENT_TIMESTAMP() AS SILVER_LOAD_DATE
FROM {{ source('wagway_netsuite', 'CLASSIFICATION') }}
