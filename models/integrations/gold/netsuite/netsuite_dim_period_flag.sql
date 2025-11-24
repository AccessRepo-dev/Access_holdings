{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') | lower == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_period_flag',
    incremental_strategy = 'merge',
    unique_key = ['DIM_PERIOD_ID','START_DATE','FLAG_TYPE']
) }}

with source as (
    select
        id as DIM_PERIOD_ID,
        date(startdate) as START_DATE,
    from {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_ACCOUNTINGPERIOD') }}
    where startdate <= current_date
      and lower(split_part(periodname, ' ', 1)) in 
          ('jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec')
),

base as (
    select
        DIM_PERIOD_ID,
        START_DATE,

        case 
            when year(START_DATE) = year(current_date)
            then 'YTD'
        end as YTD_FLAG,

        case 
            when year(START_DATE) = year(current_date)
                 and month(START_DATE) = month(current_date)
            then 'MTD'
        end as MTD_FLAG,

        case 
            when year(START_DATE) = year(current_date)
                 and quarter(START_DATE) = quarter(current_date)
            then 'QTD'
        end as QTD_FLAG,

        case 
            when START_DATE between 
                 dateadd(month, -12, date_trunc('month', current_date))
                 and date_trunc('month', dateadd(month, -1, current_date))
            then 'LTM'
        end as LTM_FLAG
    from source
),

-- Unpivot all flags into a single column
unpivoted as (
    select 
        DIM_PERIOD_ID,
        START_DATE,
        FLAG_TYPE
    from base
    unpivot (
        FLAG_TYPE for FLAG_COL in (YTD_FLAG, MTD_FLAG, QTD_FLAG, LTM_FLAG)
    )
),

-- Assign HISTORICAL flag when none of the above flags exist
final as (
    select
        b.DIM_PERIOD_ID,
        b.START_DATE,
        coalesce(u.FLAG_TYPE, 'HISTORICAL') as FLAG_TYPE
    from base b
    left join unpivoted u
        on b.DIM_PERIOD_ID = u.DIM_PERIOD_ID
)

select *
from final
order by START_DATE