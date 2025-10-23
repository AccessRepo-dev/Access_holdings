with source as (
    select *
    from {{ source('macro_raw', 'BLS_EMPLOYMENT') }}
)

select
    TRIM("series_id") as SERIES_ID,
    CAST("year" AS NUMBER) as YEAR,
    TRIM("period") as PERIOD,
    CAST(CONCAT(YEAR,SUBSTRING("period", 2, 2)) AS INT) AS DateKey,
    "value" as VALUE,
    TRIM("footnote_codes") as FOOTNOTE_CODES,
    TRIM("series_title") as SERIES_TITLE
from source