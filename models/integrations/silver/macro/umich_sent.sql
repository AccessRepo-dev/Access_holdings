with source as (
    select *
    from {{ source('macro_raw', 'UMICH_SENT') }}
)

select
    cast("Year" as integer) as YEAR,
    lpad(cast("Period" as string), 2, '0') as PERIOD,
    CAST(CONCAT(YEAR,PERIOD,'01') AS INT) AS DateKey,
    cast("series_id" as string) as SERIES_ID,
    cast("series_title" as string) as SERIES_TITLE,
    "value" as VALUE,
    cast("units" as string) as UNITS,
    cast("source" as string) as SOURCE
from source
