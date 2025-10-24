WITH fhfa_housing_cte AS (
    SELECT 
        DateKey,
        measure_name,
        measure_value,
        hash(place_id, hpi_flavor, hpi_type, frequency, DateKey) AS unique_id
    FROM {{ ref('fhfa_housing') }}
    UNPIVOT (
        measure_value FOR measure_name IN (index_nsa, index_sa)
    )
),

nahb_housing_cte AS (
    SELECT 
        DateKey,
        measure_name,
        measure_value,
        hash(MONTH, DateKey) AS unique_id
    FROM {{ ref('nahb_housing') }}
    UNPIVOT (
        measure_value FOR measure_name IN (HMI)
    )
),

bls_ppi_cte AS (
    SELECT 
        DateKey,
        Series_ID AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id
    FROM {{ ref('bls_ppi') }}
),

bls_cpi_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id
    FROM {{ ref('bls_cpi') }}
),

bot_transport_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id
    FROM {{ ref('bot_transport_index') }}
),

bls_employment_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id
    FROM {{ ref('bls_employment') }}
),

umich_sent_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id
    FROM {{ ref('umich_sent') }}
),

bea_gdp_industry_cte AS (
    SELECT 
        D.DATEKEY, 
        'Value Added by Industry' AS measure_name,
        DataValue / 12 AS measure_value,
        hash(Industry, TableID, IndustryDescription, D.DATEKEY) AS unique_id
    FROM {{ ref('bea_gdp_industry') }} B
    LEFT JOIN {{ ref('dim_date_monthly') }} D 
        ON B.YEAR = D.YEAR
),

bea_gdp_nominal_cte AS (
    SELECT 
        D.DATEKEY,
        'GDP (Nominal)' AS measure_name,
        (B.DATAVALUE / 3) AS measure_value,  -- Quarterly to monthly
        hash(B.TABLENAME, B.SERIESCODE, D.DATEKEY) AS unique_id
    FROM {{ ref('bea_gdp_nominal') }} B
    LEFT JOIN {{ ref('dim_date_monthly') }} D
        ON LEFT(B.TIMEPERIOD, 4) = D.YEAR
       AND RIGHT(B.TIMEPERIOD, 2) = D.QUARTER_NAME
),

bea_gdp_real_cte AS (
    SELECT 
        D.DATEKEY,
        'GDP (Real)' AS measure_name,
        (B.DATAVALUE / 3) AS measure_value,  -- Quarterly to monthly
        hash(B.TABLENAME, B.SERIESCODE, B.LINEDESCRIPTION, D.DATEKEY) AS unique_id
    FROM {{ ref('bea_gdp_real') }} B
    LEFT JOIN {{ ref('dim_date_monthly') }} D
        ON LEFT(B.TIMEPERIOD, 4) = D.YEAR
       AND RIGHT(B.TIMEPERIOD, 2) = D.QUARTER_NAME
),

bea_gdp_region_cte AS (
    SELECT 
        D.DATEKEY,
        'GDP by County' AS measure_name,
        DATAVALUE AS measure_value,  -- Annual repeated monthly
        hash(B.GEONAME, D.DATEKEY) AS unique_id
    FROM {{ ref('bea_gdp_region') }} B
    LEFT JOIN {{ ref('dim_date_monthly') }} D 
        ON B.TIMEPERIOD = D.YEAR
)
SELECT * FROM fhfa_housing_cte
UNION ALL
SELECT * FROM nahb_housing_cte
UNION ALL
SELECT * FROM bls_ppi_cte
UNION ALL
SELECT * FROM bls_cpi_cte
UNION ALL
SELECT * FROM bot_transport_cte
UNION ALL
SELECT * FROM bls_employment_cte
UNION ALL
SELECT * FROM umich_sent_cte
UNION ALL 
SELECT * FROM bea_gdp_industry_cte
UNION ALL 
SELECT * FROM bea_gdp_nominal_cte
UNION ALL 
SELECT * FROM bea_gdp_real_cte
UNION ALL 
SELECT * FROM bea_gdp_region_cte