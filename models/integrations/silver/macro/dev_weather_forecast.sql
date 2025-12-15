with source as (
    select *
    from {{ source('macro_raw', 'DEV_WEATHER_FORECAST') }}
)

select
    CAST("DATE" as date) as DATE,
    CAST(REPLACE(cast("DATE" as date),'-','') AS NUMBER) AS DATEKEY,
    TRIM(SPLIT_PART("CITY",',',1)) as CITY,
    TRIM(SPLIT_PART("CITY",',',2)) AS STATE,
    round("TEMP_MAX", 2)   as TEMP_MAX_24H_F,
    round("TEMP_MIN", 2)   as TEMP_MIN_24H_F,
    round("TEMP_AVG", 2)   as TEMP_AVG_24H_F, 
    round("HUMIDITY", 1) as HUMIDITY_AVG_24H_PCT,
    round("PRECIP_IN", 2)  as PRECIP_TOTAL_IN,
    round("SNOW_IN", 2)    as SNOW_TOTAL_IN,
    round("CLOUDCOVER", 1) as CLOUD_AVG_24H_PCT,
    round("WINDSPEED_MPH", 2) as WIND_AVG_24H_MPH,
    TRIM(CONDITIONS) as CONDITIONS,
    TRIM(SOURCE) as SOURCE,
    cast(left(hour,2) as int) as HOUR,
    round("TEMP", 2) as TEMP
from source