with source as (
    select *
    from {{ source('macro_raw', 'BOT_TRANSPORT_INDEX') }}
)

select
    TRIM(period) as PERIOD,
    CAST(REPLACE(period , '-', '')AS INT) AS DateKey,
    TRIM(series_id) as SERIES_ID,
    TRIM(series_title) as SERIES_TITLE,
    value as VALUE,
    TRIM(units) as UNITS
from source