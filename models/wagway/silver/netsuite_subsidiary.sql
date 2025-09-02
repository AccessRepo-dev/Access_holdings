{{ config(
    materialized = 'incremental',
    unique_key = 'SUBSIDIARY_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    CAST(ID AS INT) AS SUBSIDIARY_ID,
    TRIM(NAME) AS SUBSIDIARY_NAME,
    TRIM(FULLNAME) AS SUBSIDIARY_FULL_NAME,
    CAST(PARENT AS INT) AS PARENT_ID,
    CAST(CURRENCY AS INT) AS CURRENCY_ID,
    CAST(
        CASE 
            WHEN ISINACTIVE = 'T' THEN TRUE
            WHEN ISINACTIVE = 'F' THEN FALSE
            ELSE NULL
        END AS BOOLEAN
    ) AS IS_INACTIVE,
    CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM {{ source('wagway_netsuite', 'SUBSIDIARY') }}

{% if is_incremental() %}
WHERE CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) > (
    SELECT COALESCE(MAX(LAST_MODIFIED_DATE), '1900-01-01'::TIMESTAMP_NTZ)
    FROM {{ this }}
)
{% endif %}
