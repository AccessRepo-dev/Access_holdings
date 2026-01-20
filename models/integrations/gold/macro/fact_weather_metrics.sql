{{ config(enabled=false) }}
WITH day_level_forecast as (
    SELECT 
    date, 
    datekey, 
    city, 
    state, 
    max(temp) as TEMP_MAX_DAY_F,
    min(temp) as TEMP_MIN_DAY_F,
    avg(temp) as TEMP_AVG_DAY_F,
    sum(precip_total_in) as PRECIP_DAY_IN,
    sum(snow_total_in) as SNOW_DAY_IN,
    AVG(CLOUD_AVG_24H_PCT) as CLOUD_AVG_DAY_PCT,
    AVG(WIND_AVG_24H_MPH) as WIND_AVG_DAY_MPH,
    AVG(HUMIDITY_AVG_24H_PCT) as HUMIDITY_AVG_DAY_PCT
FROM {{ ref('weather_forecast_visualcrossing') }} 
where lower(source) = 'hourly' and HOUR between 9 and 18 
GROUP BY date, datekey, city, state

)

, day_level_historical as (
    SELECT 
    date, 
    datekey, 
    city, 
    state, 
    max(temp) as TEMP_MAX_DAY_F,
    min(temp) as TEMP_MIN_DAY_F,
    avg(temp) as TEMP_AVG_DAY_F,
    sum(precip_total_in) as PRECIP_DAY_IN,
    sum(snow_total_in) as SNOW_DAY_IN,
    AVG(CLOUD_AVG_24H_PCT) as CLOUD_AVG_DAY_PCT,
    AVG(WIND_AVG_24H_MPH) as WIND_AVG_DAY_MPH,
    AVG(HUMIDITY_AVG_24H_PCT) as HUMIDITY_AVG_DAY_PCT
FROM {{ ref('weather_daily_obs_visualcrossing') }} 
where lower(source) = 'hourly' and HOUR between 9 and 18 
GROUP BY date, datekey, city, state

)

,total_level_forecast AS 
(
SELECT 
    *,
    'WEATHER_DAILY_OBS' AS DATASET,
    'WEATHER' AS DATASOURCE

FROM {{ ref('weather_forecast_visualcrossing') }}
where lower(source) = 'daily'
)

, total_level_historical as (
    SELECT 
    *,
    'WEATHER_DAILY_OBS' AS DATASET,
    'WEATHER' AS DATASOURCE

FROM {{ ref('weather_daily_obs_visualcrossing') }}
where lower(source) = 'daily'
)
    
   , forecast as (
SELECT t.*, 
    d.TEMP_MAX_DAY_F,
    d.TEMP_MIN_DAY_F,
    d.TEMP_AVG_DAY_F,
    d.PRECIP_DAY_IN,
    d.SNOW_DAY_IN,
    d.CLOUD_AVG_DAY_PCT,
    d.WIND_AVG_DAY_MPH,
    d.HUMIDITY_AVG_DAY_PCT
FROM total_level_forecast t 
left join day_level_forecast d ON d.datekey = t.datekey and t.city = d.city and t.state = d.state

   ),

   historical as (
    SELECT t.*, 
    d.TEMP_MAX_DAY_F,
    d.TEMP_MIN_DAY_F,
    d.TEMP_AVG_DAY_F,
    d.PRECIP_DAY_IN,
    d.SNOW_DAY_IN,
    d.CLOUD_AVG_DAY_PCT,
    d.WIND_AVG_DAY_MPH,
    d.HUMIDITY_AVG_DAY_PCT
FROM total_level_historical t 
left join day_level_historical d ON d.datekey = t.datekey and t.city = d.city and t.state = d.state

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
FROM forecast a1
UNPIVOT( 
measure_value FOR measure_name IN 
    (TEMP_MAX_DAY_F, TEMP_MIN_DAY_F, TEMP_AVG_DAY_F,
    TEMP_MAX_24H_F, TEMP_MIN_24H_F, TEMP_AVG_24H_F,
    PRECIP_TOTAL_IN, PRECIP_DAY_IN, SNOW_TOTAL_IN, SNOW_DAY_IN,
    CLOUD_AVG_24H_PCT, CLOUD_AVG_DAY_PCT,
    WIND_AVG_24H_MPH, WIND_AVG_DAY_MPH,
    HUMIDITY_AVG_24H_PCT, HUMIDITY_AVG_DAY_PCT
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
FROM historical a1
UNPIVOT( 
measure_value FOR measure_name IN 
    (TEMP_MAX_DAY_F, TEMP_MIN_DAY_F, TEMP_AVG_DAY_F,
    TEMP_MAX_24H_F, TEMP_MIN_24H_F, TEMP_AVG_24H_F,
    PRECIP_TOTAL_IN, PRECIP_DAY_IN, SNOW_TOTAL_IN, SNOW_DAY_IN,
    CLOUD_AVG_24H_PCT, CLOUD_AVG_DAY_PCT,
    WIND_AVG_24H_MPH, WIND_AVG_DAY_MPH,
    HUMIDITY_AVG_24H_PCT, HUMIDITY_AVG_DAY_PCT
    )
    )