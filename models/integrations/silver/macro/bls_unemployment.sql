with source as (
    select *
    from {{ source('macro_raw', 'BLS_UNEMPLOYMENT') }}
)

select
    TRIM(series_id) as SERIES_ID,
    CAST(year AS NUMBER) as YEAR,
    TRIM(period) as PERIOD,
    CAST(CONCAT(YEAR,SUBSTRING(period, 2, 2),'01') AS INT) AS DateKey,
    CAST(REPLACE(TRIM(value),'-',0) AS INT)as VALUE,
    TRIM(series_title) as SERIES_TITLE,
    periodicity_code as periodicity_code
from source