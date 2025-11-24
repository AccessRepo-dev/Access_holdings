
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_period_flag',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['DIM_PERIOD_ID','START_DATE','FLAG_TYPE']
) }}

with source as (
    SELECT 
        RECORDNO AS DIM_PERIOD_ID,
        START_DATE
    FROM {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_REPORTING_PERIOD') }}
    WHERE LOWER(SPLIT_PART(NAME, ' ', 3)) IN 
    (
        'january','february','march','april','may','june',
        'july','august','september','october','november','december'
    )
      AND START_DATE <= CURRENT_DATE
),

base AS (
    SELECT 
        DIM_PERIOD_ID,
        START_DATE,

        CASE 
            WHEN YEAR(START_DATE) = YEAR(CURRENT_DATE) 
            THEN 'YTD' 
        END AS YTD_FLAG,

        CASE 
            WHEN YEAR(START_DATE) = YEAR(CURRENT_DATE)
                 AND MONTH(START_DATE) = MONTH(CURRENT_DATE)
            THEN 'MTD' 
        END AS MTD_FLAG,

        CASE 
            WHEN YEAR(START_DATE) = YEAR(CURRENT_DATE)
                 AND QUARTER(START_DATE) = QUARTER(CURRENT_DATE)
            THEN 'QTD' 
        END AS QTD_FLAG,

        CASE 
            WHEN START_DATE BETWEEN 
                 dateadd(month, -12, date_trunc('month', current_date))
                 and date_trunc('month', dateadd(month, -1, current_date))
            THEN 'LTM' 
        END AS LTM_FLAG
    FROM source
),

unpivoted AS (
    SELECT 
        DIM_PERIOD_ID,
        START_DATE,
        FLAG_TYPE
    FROM base
    UNPIVOT (
        FLAG_TYPE FOR FLAG_COL IN (YTD_FLAG, MTD_FLAG, QTD_FLAG, LTM_FLAG)
    )
),

final AS (
    SELECT
        b.DIM_PERIOD_ID,
        b.START_DATE,
        COALESCE(u.FLAG_TYPE, 'HISTORICAL') AS FLAG_TYPE
    FROM base b
    LEFT JOIN unpivoted u
        ON b.DIM_PERIOD_ID = u.DIM_PERIOD_ID
)

SELECT *
FROM final
ORDER BY START_DATE
