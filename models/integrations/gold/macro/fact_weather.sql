WITH SOURCE AS 
(
SELECT 
    *,
    'WEATHER_DAILY_OBS' AS DATASET,
    'WEATHER' AS DATASOURCE,

FROM {{ ref('weather_daily_obs') }}
)
    SELECT
    datekey,
    DATE,
    measure_name,
    measure_value,
    HASH(DATEKEY,CITY,STATE,measure_name) AS UNIQUE_ID,
    HASH(CITY,STATE) AS dim_granularity_id,
    HASH(CITY,STATE) AS key1,
    NULL AS key2,
    NULL AS key3,
    NULL AS key4, 
    DATASET,
    DATASOURCE
FROM source a1
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