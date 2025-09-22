with source as (
    select *
    from {{ source('macro_raw', 'CENSUS_HOUSING_COMPLETED') }}
)

select
    CAST("Total" AS NUMBER) as TOTAL,
    CAST("1 unit" AS NUMBER) as UNIT_1,
    CAST("2 to 4
 units" AS NUMBER) as UNIT_2_TO_4,
    CAST("5 units
 or more" AS NUMBER) as UNIT_5_OR_MORE,
    CAST("Total.1" AS NUMBER) as TOTAL_1,
    CAST("1 unit.1" AS NUMBER) as UNIT_1_1,
    CAST("Total.2" AS NUMBER) as TOTAL_2,
    CAST("1 unit.2" AS NUMBER) as UNIT_1_2,
    CAST("Total.3" AS NUMBER) as TOTAL_3,
    CAST("1 unit.3" AS NUMBER) as UNIT_1_3,
    CAST("Total.4" AS NUMBER) as TOTAL_4,
    CAST("1 unit.4" AS NUMBER) as UNIT_1_4,
    CAST("month" AS NUMBER) as MONTH
from source
