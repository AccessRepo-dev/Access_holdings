with source as (
    select *
    from {{ source('macro_raw', 'WEATHER_DAILY_OBS') }}
)

select
    cast("Date" as date) as DATE,
    CAST(REPLACE(cast("Date" as date),'-','') AS NUMBER) AS DATEKEY,
    TRIM(SPLIT_PART("City",',',1)) as CITY,
    TRIM(SPLIT_PART("City",',',2)) AS STATE,
    round("Temp_Max_9_18_F", 2)  as TEMP_MAX_DAY_F,
    round("Temp_Min_9_18_F", 2)  as TEMP_MIN_DAY_F,
    round("Temp_Avg_9_18_F", 2)  as TEMP_AVG_DAY_F,
    round("Temp_Max_24h_F", 2)   as TEMP_MAX_24H_F,
    round("Temp_Min_24h_F", 2)   as TEMP_MIN_24H_F,
    round("Precip_Total_in", 2)  as PRECIP_TOTAL_IN,
    round("Precip_9_18_in", 2)   as PRECIP_DAY_IN,
    round("Snow_Total_in", 2)    as SNOW_TOTAL_IN,
    round("Snow_9_18_in", 2)     as SNOW_DAY_IN,
    round("Cloud_Avg_24h_pct", 1) as CLOUD_AVG_24H_PCT,
    round("Cloud_Avg_9_18_pct", 1) as CLOUD_AVG_DAY_PCT,
    round("Wind_Avg_24h_mph", 2) as WIND_AVG_24H_MPH,
    round("Wind_Avg_9_18_mph", 2) as WIND_AVG_DAY_MPH,
    round("Humidity_Avg_24h_pct", 1) as HUMIDITY_AVG_24H_PCT,
    round("Humidity_Avg_9_18_pct", 1) as HUMIDITY_AVG_DAY_PCT
from source