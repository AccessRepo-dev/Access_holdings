with source as (
    select *
    from {{ source('macro_raw', 'FHFA_HOUSING') }}
)

select
    CAST("yr" AS NUMBER) AS YEAR,
    CAST("period" AS NUMBER) AS PERIOD,
    TRIM("hpi_type") AS HPI_TYPE,
    TRIM("hpi_flavor") AS HPI_FLAVOR,
    TRIM("frequency") AS FREQUENCY,
    TRIM("level") AS LEVEL,
    TRIM("place_id") AS PLACE_ID,
    TRIM("place_name") AS PLACE_NAME,
    TRIM(SPLIT_PART("place_name", ',', 1)) AS PLACE_LOCATION,
    TRIM(SPLIT_PART("place_name", ',', 2)) AS PLACE_STATE,
    "index_nsa" AS INDEX_NSA,
    "index_sa" AS INDEX_SA
from source
