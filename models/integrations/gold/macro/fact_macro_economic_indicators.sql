WITH fhfa_housing_cte AS (
    SELECT 
        DateKey,
        measure_name,
        measure_value,
        hash(place_id, hpi_flavor, hpi_type, frequency, DateKey) AS unique_id,
        'HOUSING' AS DATASET,
        'FHFA' AS DATASOURCE
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
        hash(MONTH, DateKey) AS unique_id,
        'HOUSING' AS DATASET,
        'National Association of Home Builders' AS DATASOURCE
    FROM {{ ref('nahb_housing') }}
    UNPIVOT (
        measure_value FOR measure_name IN (HMI)
    )
),

-- bls_ppi_cte AS (
--     SELECT 
--         DateKey,
--         'PPI'AS measure_name,
--         Value AS measure_value,
--         hash(series_id, DateKey) AS unique_id,
--         'Producer Price Index' AS DATASET,
--         'Bureau of Labor Statistics' AS DATASOURCE
--     FROM {{ ref('bls_ppi') }}
-- ),

-- bls_cpi_cte AS (
--     SELECT 
--         DateKey,
--         SERIES_TITLE AS measure_name,
--         Value AS measure_value,
--         hash(series_id, DateKey) AS unique_id,
--         'Consumer Price Index' AS DATASET,
--         'Bureau of Labor Statistics' AS DATASOURCE
--     FROM {{ ref('bls_cpi') }}
-- ),

bot_transport_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id,
        'Transport' AS DATASET,
        'BOT' AS DATASOURCE
    FROM {{ ref('bot_transport_index') }}
    WHERE ('Air Revenue Passenger Miles (Transportation Services Index)','Air Revenue Ton Miles of Freight and Mail',
    'Airline Load Factor (RPM/ASM)','Available Seat Miles','Enplanements (Boardings)','Indexed Rail Freight Carloads',
    'Indexed Rail Freight Intermodal','Industrial Production Index','International Airline Load Factor',
    'International Enplanements','Inventory to Sales Ratio','Manufacturing Output Index','Natural Gas Transport Volume',
    'Petroleum Transport Volume','Public Transit Ridership','Rail Freight Carloads','Rail Passenger Miles',
    'Revenue Passenger Miles','Transportation Services Index - Freight','Transportation Services Index - Passenger',
    'Transportation Services Index - Total','Vehicle Miles Traveled','Waterborne Freight Volume')
                 
),

-- bls_employment_cte AS (
--     SELECT 
--         DateKey,
--         SERIES_TITLE AS measure_name,
--         Value AS measure_value,
--         hash(series_id, DateKey) AS unique_id,
--         'Employment' AS DATASET,
--         'Bureau of Labor Statistics' AS DATASOURCE
--     FROM {{ ref('bls_employment') }}
-- ),

umich_sent_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id,
        'Consumer' AS DATASET,
        'Umich Survey of Consumers' AS DATASOURCE

    FROM {{ ref('umich_sent') }}
),

bea_gdp_industry_cte AS (
    SELECT 
        D.DATEKEY, 
        'Value Added by Industry' AS measure_name,
        DataValue / 12 AS measure_value,
        hash(Industry, TableID, IndustryDescription, D.DATEKEY) AS unique_id,
        'GDP' AS DATASET,
        'Bureau of Economic Analysis' AS DATASOURCE
    FROM {{ ref('bea_gdp_industry') }} B
    LEFT JOIN {{ ref('dim_date_monthly') }} D 
        ON B.YEAR = D.YEAR
),

bea_gdp_nominal_cte AS (
    SELECT 
        D.DATEKEY,
        'GDP (Nominal)' AS measure_name,
        (B.DATAVALUE / 3) AS measure_value,  -- Quarterly to monthly
        hash(B.TABLENAME, B.SERIESCODE, D.DATEKEY) AS unique_id,
        'GDP' AS DATASET,
        'Bureau of Economic Analysis' AS DATASOURCE
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
        hash(B.TABLENAME, B.SERIESCODE, B.LINEDESCRIPTION, D.DATEKEY) AS unique_id,
        'GDP' AS DATASET,
        'Bureau of Economic Analysis' AS DATASOURCE
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
        hash(B.GEONAME, D.DATEKEY) AS unique_id,
        'GDP' AS DATASET,
        'Bureau of Economic Analysis' AS DATASOURCE
    FROM {{ ref('bea_gdp_region') }} B
    LEFT JOIN {{ ref('dim_date_monthly') }} D 
        ON B.TIMEPERIOD = D.YEAR
),
adp_employment_cte AS (SELECT 
        datekey,
        measure_name,
        measure_value,
        hash(agg_ris, timestep, category,Date) AS unique_id ,
        'EMPLOYEMENT' AS DATASET,
        'ADP' AS DATASOURCE
    FROM {{ ref('adp_employment') }}
    UNPIVOT (
        measure_value FOR measure_name IN (ner, ner_sa)
    ) 
    WHERE TIMESTEP = 'M'
)
SELECT * FROM fhfa_housing_cte
UNION ALL
SELECT * FROM nahb_housing_cte
UNION ALL
-- SELECT * FROM bls_ppi_cte
-- UNION ALL
-- SELECT * FROM bls_cpi_cte
-- UNION ALL
-- SELECT * FROM bot_transport_cte
-- UNION ALL
-- SELECT * FROM bls_employment_cte
-- UNION ALL
SELECT * FROM umich_sent_cte
UNION ALL 
SELECT * FROM bea_gdp_industry_cte
UNION ALL 
SELECT * FROM bea_gdp_nominal_cte
UNION ALL 
SELECT * FROM bea_gdp_real_cte
UNION ALL 
SELECT * FROM bea_gdp_region_cte
UNION ALL 
SELECT * FROM adp_employment_cte