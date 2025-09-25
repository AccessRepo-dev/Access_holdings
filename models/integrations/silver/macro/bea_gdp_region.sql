with source as (
    select *
    from {{ source('macro_raw', 'BEA_GDP_REGION') }}
)

select
    TRIM("Code") as CODE,
    CAST("GeoFips" AS NUMBER) as GEOFIPS,
    TRIM("GeoName") as GEONAME,
    SPLIT_PART("GeoName", ',', 1) as GEONAME_REGION,
    REGEXP_REPLACE(TRIM(SPLIT_PART("GeoName", ',', 2)), '[^A-Z]', '') as GEONAME_STATE,
    CAST("TimePeriod" AS NUMBER) as TIMEPERIOD,
    TRIM("CL_UNIT") as CL_UNIT,
    CAST("UNIT_MULT" AS NUMBER) as UNIT_MULT,
    CAST("DataValue" AS NUMBER) AS DATAVALUE,
    TRIM("NoteRef") as NOTEREF
from source
