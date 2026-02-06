WITH fhfa_housing_cte AS (
    SELECT 
        hash(place_id, hpi_flavor, hpi_type,level, DateKey,frequency) AS unique_id,
        DateKey,
        measure_name,
        measure_value,
        CONCAT('place_id', '|', 'level', '|', 'hpi_flavor', '|', 'hpi_type') AS keys_list,
        CAST(place_id AS VARCHAR) AS key1,
        CAST(level AS VARCHAR) AS key2,
        CAST(hpi_flavor AS VARCHAR) AS key3,
        CAST(hpi_type AS VARCHAR) AS key4,
        --frequency AS key5  
        'HOUSING' AS DATASET,
        'Federal Housing Finance Agency' AS DATASOURCE
    FROM {{ ref('fhfa_housing') }}
    UNPIVOT (
        measure_value FOR measure_name IN (index_nsa, index_sa)
    )
),
nahb_housing_cte AS (
    SELECT DISTINCT 
        hash(DateKey) AS unique_id, 
        DateKey,
        'HMI' AS measure_name,
        CAST(HMI AS NUMBER) AS measure_value,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Housing' AS DATASET,
        'National Association of Home Builders' AS DATASOURCE
    FROM {{ ref('nahb_housing') }}
   
),

bls_ppi_cte AS (
    SELECT 
        hash(series_id, DateKey) AS unique_id,
        DateKey,
        series_id AS measure_name,
        Value AS measure_value,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Producer Price Index' AS DATASET,
        'Bureau of Labor Statistics' AS DATASOURCE
    FROM {{ ref('bls_ppi') }}
   
),

bls_cpi_cte AS (
    SELECT 
        hash(series_id, DateKey) AS unique_id,
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        CONCAT('Area_Code', '|', 'Item_Code', '|', 'Seasonal', '|', 'Base_Period') AS keys_list,
        CAST(Area_code AS VARCHAR) AS key1,
        CAST(Item_Code AS VARCHAR) AS key2,
        SEASONAL AS key3,
        BASE_PERIOD AS key4, 
        'Consumer Price Index' AS DATASET,
        'Bureau of Labor Statistics' AS DATASOURCE
    FROM {{ ref('bls_cpi') }}
),

bot_transport_cte AS (
    SELECT 
        hash(series_id, DateKey) AS unique_id,
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        'units' AS keys_list,
        units AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Transport' AS DATASET,
        'Bureau of Transportation' AS DATASOURCE
    FROM {{ ref('bot_transport_index') }}
  
                 
),

bls_employment_cte AS (
    SELECT 
        hash(series_id, DateKey) AS unique_id,
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Employment' AS DATASET,
        'Bureau of Labor Statistics' AS DATASOURCE
    FROM {{ ref('bls_employment') }}
   
),

bls_unemployment_cte AS (
    SELECT 
        hash(series_id, DateKey) AS unique_id,
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        'periodicity_code' AS keys_list,
        periodicity_code AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Unemployment' AS DATASET,
        'Bureau of Labor Statistics' AS DATASOURCE
    FROM {{ ref('bls_unemployment') }}
   
),

umich_sent_cte AS (
    SELECT 
        hash(series_id, DateKey) AS unique_id,
        D.DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
        NULL AS keys_list,
        NULL AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'Consumer' AS DATASET,
        'Umich Survey of Consumers' AS DATASOURCE

    FROM {{ ref('umich') }} A
      LEFT JOIN {{ ref('dim_date_monthly') }} D 
     ON  A.DATE = D.FULL_DATE
),

bea_gdp_industry_cte AS (
    SELECT 
        hash(Industry, TableID, IndustryDescription, D.DATEKEY) AS unique_id,
        D.DATEKEY, 
        'Value Added by Industry' AS measure_name,
        DataValue / 12 AS measure_value,
        CONCAT('Industry', '|', 'IndustryDescription', '|', 'TableID') AS keys_list,
        Industry AS key1,
        IndustryDescription AS key2,
        CAST(TableID AS VARCHAR) AS key3,
        NULL AS key4, 
        'GDP Industry' AS DATASET,
        'Bureau of Economic Analysis' AS DATASOURCE
    FROM {{ ref('bea_gdp_industry') }} B
    LEFT JOIN {{ ref('dim_date_monthly') }} D 
        ON B.YEAR = D.YEAR
),

bea_gdp_nominal_cte AS (
    SELECT 
        hash(B.SERIESCODE, D.DATEKEY) AS unique_id,
        D.DATEKEY,
        'GDP (Nominal)' AS measure_name,
        (B.DATAVALUE / 3) AS measure_value,  -- Quarterly to monthly
         CONCAT( 'LineDescription') AS keys_list,
        LINEDESCRIPTION AS key1,
        NULL AS key2,
        NULL AS key3,
        NULL AS key4, 
        'GDP Nominal' AS DATASET,
        'Bureau of Economic Analysis' AS DATASOURCE
    FROM {{ ref('bea_gdp_nominal') }} B
    LEFT JOIN {{ ref('dim_date_monthly') }} D
        ON LEFT(B.TIMEPERIOD, 4) = D.YEAR
       AND RIGHT(B.TIMEPERIOD, 2) = D.QUARTER_NAME
),

bea_gdp_real_cte AS (
    SELECT 
        hash(B.TABLENAME, B.SERIESCODE, B.LINEDESCRIPTION, D.DATEKEY) AS unique_id,
        D.DATEKEY,
        'GDP (Real)' AS measure_name,
        (B.DATAVALUE / 3) AS measure_value,  -- Quarterly to monthly
        CONCAT( 'LineDescription') AS keys_list,
        LINEDESCRIPTION AS key1,
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
        hash(B.GEONAME, D.DATEKEY) AS unique_id,
        D.DATEKEY,
        'GDP by County' AS measure_name,
        DATAVALUE AS measure_value,  -- Annual repeated monthly
       CONCAT('Geoname', '|', 'Geoname_region','|','Geoname_state') AS keys_list,
        GEONAME AS key1,
        GEONAME_REGION AS key2,
        GEONAME_STATE AS key3,
        NULL AS key4, 
        'GDP Region' AS DATASET,
        'Bureau of Economic Analysis' AS DATASOURCE
    FROM {{ ref('bea_gdp_region') }} B
    LEFT JOIN {{ ref('dim_date_monthly') }} D 
        ON B.TIMEPERIOD = D.YEAR
),
adp_employment_cte AS (
    SELECT 
        hash(agg_ris, category,Date) AS unique_id ,
        datekey,
        measure_name,
        measure_value,
        CONCAT('Category', '|', 'AGG_RIS','|','TIMESTEP') AS keys_list,
        Category AS key1,
        AGG_RIS AS key2,
        TIMESTEP AS key3,
        NULL AS key4, 
        'EMPLOYEMENT' AS DATASET,
        'ADP' AS DATASOURCE
    FROM {{ ref('adp_employment') }}
    UNPIVOT (
        measure_value FOR measure_name IN (ner, ner_sa)
    ) 
   
),
adp_payinsights_cte AS (
    SELECT 
        hash(category,datekey) AS unique_id ,
        datekey,
        measure_name,
        measure_value,
        CONCAT('Category', '|', 'AGG','|','TIMESTEP') AS keys_list,
        Category AS key1,
        AGG AS key2,
        TIMESTEP AS key3,
        NULL AS key4, 
        'PAYINSIGHTS' AS DATASET,
        'ADP' AS DATASOURCE
    FROM {{ ref('adp_payinsights') }}
    UNPIVOT (
        measure_value FOR measure_name IN (median_pay_change, median_annual_pay)
    ) 
   
),
census_housing_starts_cte AS (
    SELECT   
        hash(DateKey) AS unique_id,
        DateKey,
        'housing_starts_total_units' as measure_name,
        Total as measure_value,
        CONCAT('Unit_1', '|', 'Unit_2_to_4','|','Unit_5_or_more') AS keys_list,
        CAST(Unit_1 AS VARCHAR) AS key1,
        CAST(Unit_2_to_4 AS VARCHAR) AS key2,
        CAST(Unit_5_or_more AS VARCHAR) AS key3,
        NULL AS key4, 
        'Housing_starts' AS DATASET,
        'Census' AS DATASOURCE
    FROM {{ ref('census_housing_starts') }}
),
census_housing_completed_cte AS (
    SELECT
        hash(DateKey) AS unique_id,   
        DateKey,
        'housing_completed_total_units' as measure_name,
        Total as measure_value,
        CONCAT('Unit_1', '|', 'Unit_2_to_4','|','Unit_5_or_more') AS keys_list,
        CAST(Unit_1 AS VARCHAR) AS key1,
        CAST(Unit_2_to_4 AS VARCHAR) AS key2,
        CAST(Unit_5_or_more AS VARCHAR) AS key3,
        NULL AS key4, 
        'Housing_completed' AS DATASET,
        'Census' AS DATASOURCE
    FROM {{ ref('census_housing_completed') }}
),
fred_cte AS (
    SELECT 
        hash(series_id, DateKey) AS unique_id,
        DateKey,
        SERIES_TITLE AS measure_name,
        Value AS measure_value,
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