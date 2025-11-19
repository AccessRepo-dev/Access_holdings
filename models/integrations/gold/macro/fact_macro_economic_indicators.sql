WITH fhfa_housing_cte AS (
    SELECT 
        D.DateKey,
        measure_name,
        measure_value / 3 AS measure_value,
        hash(place_id, hpi_flavor, hpi_type,level, D.DateKey,frequency) AS unique_id,
        CONCAT('fhfa',place_id, hpi_flavor, hpi_type,level, D.DateKey) AS keys_list,
        place_id AS key1,
        level AS key2,
        hpi_flavor AS key3,
        hpi_type AS key4,  
        'HOUSING' AS DATASET,
        'Federal Housing Finance Agency' AS DATASOURCE
    FROM {{ ref('fhfa_housing') }} A
    UNPIVOT (
        measure_value FOR measure_name IN (index_nsa, index_sa)
    )
    LEFT JOIN {{ ref('dim_date_monthly') }} D 
        ON A.YEAR = D.YEAR
        AND  A.PERIOD = D.QUARTER
    
    WHERE level = 'State' AND  HPI_TYPE = 'traditional' AND
    HPI_FLAVOR = 'purchase-only' AND A.YEAR >=2000
),
nahb_housing_cte AS (
    SELECT DISTINCT  
        DateKey,
        measure_name,
        measure_value,
        hash(DateKey) AS unique_id,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Housing' AS DATASET,
        'National Association of Home Builders' AS DATASOURCE
    FROM {{ ref('nahb_housing') }}
    UNPIVOT (
        measure_value FOR measure_name IN (HMI)
    )
),

bls_ppi_cte AS (
    SELECT 
        DateKey,
        series_id AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
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
        NULL AS keys_list, 
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Consumer Price Index' AS DATASET,
        'Bureau of Labor Statistics' AS DATASOURCE,

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
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Transport' AS DATASET,
        'Bureau of Transportation' AS DATASOURCE
    FROM {{ ref('bot_transport_index') }}
    WHERE SERIES_TITLE in ('Air Revenue Passenger Miles (Transportation Services Index)','Air Revenue Ton Miles of Freight and Mail',
    'Airline Load Factor (RPM/ASM)','Available Seat Miles','Enplanements (Boardings)','Indexed Rail Freight Carloads',
    'Indexed Rail Freight Intermodal','Industrial Production Index','International Airline Load Factor',
    'International Enplanements','Inventory to Sales Ratio','Manufacturing Output Index','Natural Gas Transport Volume',
    'Petroleum Transport Volume','Public Transit Ridership','Rail Freight Carloads','Rail Passenger Miles',
    'Revenue Passenger Miles','Transportation Services Index - Freight','Transportation Services Index - Passenger',
    'Transportation Services Index - Total','Vehicle Miles Traveled','Waterborne Freight Volume')
                 
),

bls_employment_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Employment' AS DATASET,
        'Bureau of Labor Statistics' AS DATASOURCE
    FROM {{ ref('bls_employment') }}
    WHERE SERIES_ID IN ('CES0000000001','CES0500000001','CES9000000001')
),

bls_unemployment_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Unemployment' AS DATASET,
        'Bureau of Labor Statistics' AS DATASOURCE
    FROM {{ ref('bls_unemployment') }}
    WHERE SERIES_ID IN ('LNS14000000')
    AND  YEAR >=2000
),

umich_sent_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
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
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'GDP Industry' AS DATASET,
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
        hash(B.SERIESCODE, D.DATEKEY) AS unique_id,
        (LINENUMBER) AS keys_list,
        LINENUMBER AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'GDP Nominal' AS DATASET,
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
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'GDP Real' AS DATASET,
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
        NULL AS keys_list,
        HASH(GEONAME_REGION,GEONAME_STATE) AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'GDP Region' AS DATASET,
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
        hash(agg_ris, category,Date) AS unique_id ,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
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
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'PAYINSIGHTS' AS DATASET,
        'ADP' AS DATASOURCE
    FROM {{ ref('adp_payinsights') }}
    UNPIVOT (
        measure_value FOR measure_name IN (median_pay_change, median_annual_pay)
    ) 
    WHERE TIMESTEP = 'M'
),
census_housing_starts_cte AS (
    SELECT   
        DateKey,
        'housing_starts_total_units' as measure_name,
        Total as measure_value,
        hash(DateKey) AS unique_id,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Housing_starts' AS DATASET,
        'Census' AS DATASOURCE
    FROM {{ ref('census_housing_starts') }}
),
census_housing_completed_cte AS (
    SELECT   
        DateKey,
        'housing_completed_total_units' as measure_name,
        Total as measure_value,
        hash(DateKey) AS unique_id,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Housing_completed' AS DATASET,
        'Census' AS DATASOURCE
    FROM {{ ref('census_housing_completed') }}
),
fred_cte AS (
    SELECT 
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        hash(series_id, DateKey) AS unique_id,
        NULL AS keys_list, 
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'FRED' AS DATASET,
        'Federal Reserve Economic Data' AS DATASOURCE,

    FROM {{ ref('fred') }}

)

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
UNION ALL 
SELECT * FROM adp_employment_cte
UNION ALL 
SELECT * FROM census_housing_completed_cte
UNION ALL 
SELECT * FROM census_housing_starts_cte
UNION ALL
SELECT * FROM bls_unemployment_cte
UNION ALL
SELECT * FROM fred_cte