with source as (
    select *
    from {{ source('macro_raw', 'BEA_GDP_REAL') }}
)

select
    TRIM("TableName") as TABLENAME,
    TRIM("SeriesCode") as SERIESCODE,
    CAST("LineNumber" AS NUMBER) as LINENUMBER,
    TRIM("LineDescription") as LINEDESCRIPTION,
    TRIM("TimePeriod") as TIMEPERIOD,
    TRIM("METRIC_NAME") as METRICNAME,
    TRIM("CL_UNIT") as CLUNIT,
    CAST("UNIT_MULT" AS NUMBER) as UNITMULT,
    TO_NUMBER(REPLACE("DataValue", ',', '')) AS DATAVALUE,
    TRIM("NoteRef") as NOTEREF
from source
