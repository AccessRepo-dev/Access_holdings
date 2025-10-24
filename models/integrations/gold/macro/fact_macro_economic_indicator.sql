WITH fhfa_housing AS (
    SELECT 
        DateKey,
        measure_name,
        measure_value,
        hash(place_id, hpi_flavor, hpi_type, frequency,DateKey) AS unique_id
    FROM {{ source('macro_raw', 'FHFA_HOUSING') }}
    UNPIVOT (
        measure_value FOR measure_name IN (index_nsa, index_sa)
    )
),

nahb_housing AS (
    SELECT 
        DateKey,
        measure_name,
        measure_value,
        hash(MONTH,DateKey) AS unique_id
    FROM {{ source('macro_raw', 'NAHB_HOUSING') }}
    UNPIVOT (
        measure_value FOR measure_name IN (HMI)
    )
),

bls_ppi AS (
    SELECT 
        DateKey,
        Series_ID AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id
    FROM {{ source('macro_raw', 'BLS_PPI') }}
),

bls_cpi AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id
    FROM {{ source('macro_raw', 'BLS_CPI') }}
),

bot_transport AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id
    FROM {{ source('macro_raw', 'BOT_TRANSPORT_INDEX') }}
),

bls_employment AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id
    FROM {{ source('macro_raw', 'BLS_EMPLOYMENT') }}
),

umich_sent AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id
    FROM {{ source('macro_raw', 'UMICH_SENT') }}
)

SELECT * FROM fhfa_housing
UNION ALL
SELECT * FROM nahb_housing
UNION ALL
SELECT * FROM bls_ppi
UNION ALL
SELECT * FROM bls_cpi
UNION ALL
SELECT * FROM bot_transport
UNION ALL
SELECT * FROM bls_employment
UNION ALL
SELECT * FROM umich_sent
