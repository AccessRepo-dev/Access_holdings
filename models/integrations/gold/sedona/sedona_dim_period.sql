{% set company = var('company', 'zeus') | lower %}
{{ config(enabled = var('company', 'zeus') in ['zeus']   and var('sourcesystem', 'sedona') == 'sedona')}}


{{ config(
    database = get_target_database(company),
    alias = 'dim_period',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['START_DATE']
) }}
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
    SELECT COALESCE(MAX(dim_period_id), 0) AS max_no
    FROM {{ this }}
),
{% endif %}
final AS (
SELECT
    {% if is_incremental() %}
        (SELECT max_no FROM max_recordno) + row_number() OVER (ORDER BY month_start) AS dim_period_id,
    {% else %}
        row_number() OVER (ORDER BY month_start) AS dim_period_id,
    {% endif %}
    'Month Ended ' || to_char(month_start, 'MMMM YYYY') AS PERIOD_NAME,
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