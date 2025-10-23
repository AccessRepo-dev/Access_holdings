with source as (
    select *
    from {{ source('macro_raw', 'BLS_PPI') }}
)

select
    TRIM("series_id") as SERIES_ID,
    CAST("year" AS NUMBER) as YEAR,
    TRIM("period") as PERIOD,
    "value" as VALUE,
    CAST(CONCAT("year",SUBSTRING("period", 2, 2)) AS INT) AS DATEKEY,
    TRIM("footnote_codes_x") as FOOTNOTE_CODES_X,
    TRIM("area_code") as AREA_CODE,
    TRIM("item_code") as ITEM_CODE,
    TRIM("seasonal") as SEASONAL,
    TRIM("periodicity_code") as PERIODICITY_CODE,
    TRIM("base_code") as BASE_CODE,
    TRIM("base_period") as BASE_PERIOD,
    TRIM("series_title") as SERIES_TITLE,
    TRIM("footnote_codes_y") as FOOTNOTE_CODES_Y,
    CAST("begin_year" AS NUMBER) as BEGIN_YEAR,
    TRIM("begin_period") as BEGIN_PERIOD,
    CAST("end_year" AS NUMBER) as END_YEAR,
    TRIM("end_period") as END_PERIOD
from source
