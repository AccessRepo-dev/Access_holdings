WITH SOURCE AS 
(
SELECT 
    *,
    'WEATHER_DAILY_OBS' AS DATASET,
    'WEATHER' AS DATASOURCE,

FROM {{ ref('dev_weather_forecast') }}
)

, HISTORICAL as (
    SELECT 
    *,
    'WEATHER_DAILY_OBS' AS DATASET,
    'WEATHER' AS DATASOURCE,

FROM {{ ref('dev_weather_daily_ops') }}

)
    SELECT
    datekey,
    DATE,
    measure_name,
    measure_value,
    HASH(DATEKEY,CITY,STATE,measure_name) AS UNIQUE_ID,
    CONCAT(CITY,STATE) AS keys_list,
    HASH(CITY,STATE) AS key1,
    NULL AS key2,
    NULL AS key3,
    NULL AS key4, 
    DATASET,
    DATASOURCE
FROM source a1
UNPIVOT( 
measure_value FOR measure_name IN 
    (TEMP_MAX_24H_F, TEMP_MIN_24H_F, TEMP_AVG_24H_F,
    PRECIP_TOTAL_IN, SNOW_TOTAL_IN,
    CLOUD_AVG_24H_PCT,
    WIND_AVG_24H_MPH,
    HUMIDITY_AVG_24H_PCT
    )
    )

    UNION

    SELECT
    datekey,
    DATE,
    measure_name,
    measure_value,
    HASH(DATEKEY,CITY,STATE,measure_name) AS UNIQUE_ID,
    CONCAT(CITY,STATE) AS keys_list,
    HASH(CITY,STATE) AS key1,
    NULL AS key2,
    NULL AS key3,
    NULL AS key4, 
    DATASET,
    DATASOURCE
FROM HISTORICAL a1
UNPIVOT( 
measure_value FOR measure_name IN 
    (TEMP_MAX_24H_F, TEMP_MIN_24H_F, TEMP_AVG_24H_F,
    PRECIP_TOTAL_IN, SNOW_TOTAL_IN,
    CLOUD_AVG_24H_PCT,
    WIND_AVG_24H_MPH,
    HUMIDITY_AVG_24H_PCT
    )
    )