{{ config(
    materialized = 'incremental',
    unique_key = 'LOCATION_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    fullname AS LOCATION_FULL_NAME,
    CAST(id AS INT) AS LOCATION_ID,
    isinactive AS IS_INACTIVE,
    CAST(lastmodifieddate AS DATE) AS LAST_MODIFIED_DATE,
    CAST(latitude AS FLOAT) AS LATITUDE,
    locationtype AS LOCATION_TYPE,
    CAST(longitude AS FLOAT) AS LONGITUDE,
    name AS LOCATION_NAME,
    CAST(parent AS INT) AS PARENT_ID,
    CAST(subsidiary AS INT) AS SUBSIDIARY_ID,
    CURRENT_TIMESTAMP()::TIMESTAMP AS SILVER_LOAD_DATE
FROM {{ source('wagway_netsuite', 'LOCATION') }}