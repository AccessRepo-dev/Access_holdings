with source as (
    select *
    from {{ source('macro_raw', 'BLS_EMPLOYMENT') }}
)

select
    TRIM(series_id) as SERIES_ID,
    CAST(year AS NUMBER) as YEAR,
    TRIM(period) as PERIOD,
    CAST(CONCAT(YEAR,SUBSTRING(period, 2, 2),'01') AS INT) AS DateKey,
    COALESCE(TRY_TO_NUMBER(value), 0) as value ,
    TRIM(series_title) as SERIES_TITLE
from source