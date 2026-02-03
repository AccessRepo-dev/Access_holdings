with source as (
    select *
    from {{ source('macro_raw', 'BLS_PPI') }}
)

select
    TRIM(series_id) as SERIES_ID,
    CAST(year AS NUMBER) as YEAR,
    TRIM(period) as PERIOD,
    value as VALUE,
    CAST(CONCAT(year,SUBSTRING(period, 2, 2)) AS INT) AS DATEKEY,
    TRIM(item_code) as ITEM_CODE,
    TRIM(seasonal) as SEASONAL,
    TRIM(series_title) as SERIES_TITLE,
    CAST(begin_year AS NUMBER) as BEGIN_YEAR,
    TRIM(begin_period) as BEGIN_PERIOD,
    CAST(end_year AS NUMBER) as END_YEAR,
    TRIM(end_period) as END_PERIOD
from source
