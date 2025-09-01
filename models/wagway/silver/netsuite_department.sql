{{ config(
    materialized = 'incremental',
    unique_key = 'DEPARTMENT_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    CAST(ID AS INT) AS DEPARTMENT_ID,
    FULLNAME AS FULL_NAME,
    NAME AS DEPARTMENT_NAME,
    CAST(PARENT AS INT) AS PARENT_ID,
    ISINACTIVE AS IS_INACTIVE,
    CAST(LASTMODIFIEDDATE AS DATE) AS LAST_MODIFIED_DATE,
    CURRENT_TIMESTAMP() AS SILVER_LOAD_DATE
FROM {{ source('wagway_netsuite', 'DEPARTMENT') }}
