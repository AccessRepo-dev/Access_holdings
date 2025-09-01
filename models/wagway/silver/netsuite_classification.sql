{{ config(
    materialized = 'incremental',
    unique_key = 'CLASS_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    CAST(ID AS INT) AS CLASS_ID,
    CAST(EXTERNALID AS INT) AS EXTERNALID,
    TRIM(NAME) AS CLASS_NAME,
    TRIM(FULLNAME) AS CLASS_FULL_NAME,
    CAST(PARENT AS INT) AS PARENT,
    CAST(
        CASE 
            WHEN ISINACTIVE = 'T' THEN TRUE
            WHEN ISINACTIVE = 'F' THEN FALSE
            ELSE NULL
        END AS BOOLEAN
    ) AS IS_INACTIVE,
    CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM {{ source('wagway_netsuite', 'CLASSIFICATION') }}

{% if is_incremental() %}
WHERE CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) > (
    SELECT COALESCE(MAX(LAST_MODIFIED_DATE), '1900-01-01'::TIMESTAMP_NTZ)
    FROM {{ this }}
)
{% endif %}
