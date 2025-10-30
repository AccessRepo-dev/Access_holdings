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
    SELECT DISTINCT  
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

bls_ppi_cte AS (
    SELECT 
        DateKey,
        'PPI'AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id,
        'Producer Price Index' AS DATASET,
        'Bureau of Labor Statistics' AS DATASOURCE
    FROM {{ ref('bls_ppi') }}
    WHERE series_id IN  ('WPUFD4','WPUFD4L1T15','WPUFD4131','WPUFD41302','WPUFD41303','WPU05','WPU02','WPU301')
),

bls_cpi_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id,
        'Consumer Price Index' AS DATASET,
        'Bureau of Labor Statistics' AS DATASOURCE
    FROM {{ ref('bls_cpi') }}
    WHERE SERIES_ID IN  ('CUUR0000SA0','CUUR0000SA0L1E','CUUR0000SAF1','CUUR0000SAF11','CUUR0000SEFV','CUUR0000SA0E',
    'CUUR0000SEHA','CUUR0000SETA01','CUUR0000SETA02','CUUR0000SAM','CUUR0000SAF','CUUR0000SETB01')
),

bot_transport_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id,
        'Transport' AS DATASET,
        'Bureau of Transportation' AS DATASOURCE
    FROM {{ ref('bot_transport_index') }}
    WHERE Value in ('Air Revenue Passenger Miles (Transportation Services Index)','Air Revenue Ton Miles of Freight and Mail',
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
    WHERE SERIESCODE = 'A191RC'
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
    WHERE SERIESCODE = 'A191RX'
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
adp_employment_cte AS (
    SELECT 
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
),
adp_payinsights_cte AS (
    SELECT 
        datekey,
        measure_name,
        measure_value,
        hash(category,datekey) AS unique_id ,
        'PAYINSIGHTS' AS DATASET,
        'ADP' AS DATASOURCE
    FROM {{ ref('adp_payinsights') }}
    UNPIVOT (
        measure_value FOR measure_name IN (median_pay_change, median_annual_pay)
    ) 
    WHERE TIMESTEP = 'M'
),
aggregated_weather_data AS (
    SELECT 
        DATEKEY,
        CITY,
        STATE,
        'WEATHER_DAILY_OBS' AS DATASET,
        'WEATHER' AS DATASOURCE,
        ROUND(MAX(TEMP_MAX_DAY_F),2) AS TEMP_MAX_DAY_F,
        ROUND(MIN(TEMP_MIN_DAY_F),2) AS TEMP_MIN_DAY_F,
        ROUND(AVG(TEMP_AVG_DAY_F),2) AS TEMP_AVG_DAY_F,
        ROUND(MAX(TEMP_MAX_24H_F),2) AS TEMP_MAX_24H_F,
        ROUND(MIN(TEMP_MIN_24H_F),2) AS TEMP_MIN_24H_F,
        ROUND(AVG(PRECIP_TOTAL_IN),2) AS PRECIP_TOTAL_IN,
        ROUND(AVG(PRECIP_DAY_IN),2) AS PRECIP_DAY_IN,
        ROUND(AVG(SNOW_TOTAL_IN),2) AS SNOW_TOTAL_IN,
        ROUND(AVG(SNOW_DAY_IN),2) AS SNOW_DAY_IN,
        ROUND(AVG(CLOUD_AVG_24H_PCT),2) AS CLOUD_AVG_24H_PCT,
        ROUND(AVG(CLOUD_AVG_DAY_PCT),2) AS CLOUD_AVG_DAY_PCT,
        ROUND(AVG(WIND_AVG_24H_MPH),2) AS WIND_AVG_24H_MPH,
        ROUND(AVG(WIND_AVG_DAY_MPH),2) AS WIND_AVG_DAY_MPH,
        ROUND(AVG(HUMIDITY_AVG_24H_PCT),2) AS HUMIDITY_AVG_24H_PCT,
        ROUND(AVG(HUMIDITY_AVG_DAY_PCT),2) AS HUMIDITY_AVG_DAY_PCT
    FROM {{ ref('weather_daily_obs') }}
    GROUP BY 
        DATEKEY, CITY, STATE
),
weather_cte as (SELECT
    datekey,
    measure_name,
    measure_value,
    HASH(DATEKEY,CITY) AS UNIQUE_ID,
    DATASET,
    DATASOURCE
FROM aggregated_weather_data a1
UNPIVOT( 
measure_value FOR measure_name IN 
    (TEMP_MAX_DAY_F, TEMP_MIN_DAY_F, TEMP_AVG_DAY_F,
    TEMP_MAX_24H_F, TEMP_MIN_24H_F,
    PRECIP_TOTAL_IN, PRECIP_DAY_IN, SNOW_TOTAL_IN, SNOW_DAY_IN,
    CLOUD_AVG_24H_PCT, CLOUD_AVG_DAY_PCT,
    WIND_AVG_24H_MPH, WIND_AVG_DAY_MPH,
    HUMIDITY_AVG_24H_PCT, HUMIDITY_AVG_DAY_PCT
    )
    )
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
UNION ALL 
SELECT * FROM weather_cte