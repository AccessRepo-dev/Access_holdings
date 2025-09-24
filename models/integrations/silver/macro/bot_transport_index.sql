with source as (
    select *
    from {{ source('macro_raw', 'BOT_TRANSPORT_INDEX') }}
)

select
    cast("year" as integer) as YEAR,
    TRIM("period") as PERIOD,
    TRIM("series_id") as SERIES_ID,
    TRIM("series_title") as SERIES_TITLE,
    "value" as VALUE,
    TRIM("units") as UNITS,
    TRIM("source") as SOURCE
from source