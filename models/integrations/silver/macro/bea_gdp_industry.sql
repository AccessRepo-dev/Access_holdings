with source as (
    select *
    from {{ source('macro_raw', 'BEA_GDP_INDUSTRY') }}
)

select
    CAST("TableID" AS INTEGER) as TABLEID,
    TRIM("Frequency")           as FREQUENCY,
    CAST("Year" AS INTEGER) as YEAR,
    CAST("Quarter"AS VARCHAR) as QUARTER,
    "Industry"            as INDUSTRY,
    "IndustrYDescription" as INDUSTRYDESCRIPTION,
    cast("DataValue" as float) as DATAVALUE,
    SPLIT_PART("NoteRef",';',1) AS NOTEREF,
    SPLIT_PART("NoteRef",';',2) AS NOTEREF_2,
from source