with source as (
    select *
    from {{ source('macro_raw', 'FRED') }}
)

select
    TRIM(SERIES_ID) as SERIES_ID,
    CAST("YEAR" AS NUMBER) as YEAR,
    TRIM("PERIOD") as PERIOD,
    CAST(CONCAT(YEAR,SUBSTRING("PERIOD", 2, 2),'01') AS INT) AS DateKey,
    "VALUE" as VALUE,
    TRIM("SERIES_NAME") as SERIES_TITLE,
    "DATE",
    "UNITS",
    "SOURCE"
    from source