{% set company = var('company', 'spotless') | lower %}
{% set sourcesystem = var('sourcesystem', 'sage') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}
{{ config(enabled = var('company', 'spotless') in ['spotless','amh']) }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}
{%if company != 'amh'%}
with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'REPORTING_PERIOD') }}
    
    {% if is_incremental() %}
    where 
        (
            HEADER_1 ilike '%month%' and START_DATE is not null
            and    
        cast(WHENMODIFIED as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
        )
        or _FIVETRAN_DELETED = true
    {% else %}
    WHERE
    HEADER_1 ilike '%month%' and START_DATE is not null
    {% endif %}


),

cleaned as (

   SELECT
    -- Primary Key
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,

    -- Core Info
    TRIM(NAME) AS NAME,
    CASE 
        WHEN STATUS = 'active' THEN FALSE 
        ELSE TRUE 
    END AS STATUS,
    -- Dates
    CAST(START_DATE AS DATE) AS START_DATE,
    CAST(YEAR(START_DATE) || LPAD(MONTH(START_DATE), 2, '0') || LPAD(DAY(START_DATE), 2, '0')AS INTEGER) AS DATE_KEY,
    CAST(END_DATE AS DATE) AS END_DATE,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Fivetran
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    -- Silver Load Metadata
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM source_data


)

select *
from cleaned

{%else%}

    WITH base AS (
    -- Generate months from 2017-01-01 to 5 years into the future
    -- Dynamic rowcount: calculates months needed from 2017 to (current_year + 5)
    SELECT
        dateadd(month, seq4(), to_date('2017-01-01')) AS month_start
    FROM table(generator(
        rowcount => (year(current_date()) - 2017 + 6) * 12
    ))
),
filtered AS (
    SELECT
        month_start
    FROM base
    WHERE month_start <= dateadd(year, 5, date_trunc('month', current_date()))
),
{% if is_incremental() %}
-- Only select new months that don't exist in the target table
new_months AS (
    SELECT f.*
    FROM filtered f
    LEFT JOIN {{ this }} t
        ON f.month_start = t.start_date
    WHERE t.start_date IS NULL
),
-- Get the max record number from existing data to continue sequence
max_recordno AS (
    SELECT COALESCE(MAX(recordno), 0) AS max_no
    FROM {{ this }}
),
{% endif %}
final AS (
SELECT
    {% if is_incremental() %}
        (SELECT max_no FROM max_recordno) + row_number() OVER (ORDER BY month_start) AS recordno,
    {% else %}
        row_number() OVER (ORDER BY month_start) AS recordno,
    {% endif %}
    'Month Ended ' || to_char(month_start, 'MMMM YYYY') AS name,
    FALSE AS STATUS,
    month_start AS start_date,
    to_number(to_char(month_start, 'YYYYMMDD')) AS datekey,
    last_day(month_start) AS end_date,
    NULL AS WHENMODIFIED,
    NULL AS _FIVETRAN_DELETED ,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
FROM
    {% if is_incremental() %}
        new_months
    {% else %}
        filtered
    {% endif %}
)
SELECT
    *
FROM final
{%endif%}
