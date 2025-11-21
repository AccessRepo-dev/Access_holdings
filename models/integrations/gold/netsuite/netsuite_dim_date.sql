
{% set company = var('company', 'unknown_company') | lower %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'netsuite',
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_date',
    incremental_strategy = 'append',
    unique_key = 'DATE_KEY'
) }}

with base as (
    -- Instead of dynamic rowcount, generate a large constant set of rows (e.g., 50k = ~137 years)
    select dateadd(day, seq4(), cast('2019-01-01' as date)) as DATE_VALUE
    from table(generator(rowcount => 50000))
),

date_spine as (
    {% if is_incremental() %}

        -- Incremental: only dates greater than the current max in {{ this }}
        select b.DATE_VALUE
        from base b
        join (select max(DATE_VALUE) as max_date from {{ this }}) m
          on b.DATE_VALUE > m.max_date
        where b.DATE_VALUE <= dateadd(year, 5, current_date)

    {% else %}

        -- Full load: from 2019-01-01 until today+5 years
        select b.DATE_VALUE
        from base b
        where b.DATE_VALUE <= dateadd(year, 5, current_date)

    {% endif %}
),

final as (
    select
        cast(DATE_VALUE as date) as DATE_VALUE,
        cast(to_char(DATE_VALUE, 'YYYYMMDD') as int) as DATE_KEY,

        -- Calendar breakdown
        extract(year from DATE_VALUE) as YEAR,
        extract(quarter from DATE_VALUE) as QUARTER,
        extract(month from DATE_VALUE) as MONTH,
        to_char(DATE_VALUE, 'Mon') as MONTH_NAME,
        extract(week from DATE_VALUE) as WEEK_OF_YEAR,
        extract(day from DATE_VALUE) as DAY_OF_MONTH,
        TO_CHAR(DATE_VALUE, 'DY') AS DAY_ABBR  , 
        -- Weekday flag (1 = weekday, 0 = weekend)
        case when dayofweek(DATE_VALUE) in (1,7) then 0 else 1 end as IS_WEEKDAY,

        -- Start/End markers
        date_trunc('month', DATE_VALUE) as START_OF_MONTH,
        last_day(DATE_VALUE) as END_OF_MONTH,
        date_trunc('quarter', DATE_VALUE) as START_OF_QUARTER,
        dateadd(day, -1, dateadd(quarter, 1, date_trunc('quarter', DATE_VALUE))) as END_OF_QUARTER
    from date_spine
)

select *
from final