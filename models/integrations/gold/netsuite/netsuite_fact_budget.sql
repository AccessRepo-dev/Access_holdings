{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'fact_budget',
    incremental_strategy = 'merge',
    unique_key = 'BUDGET_ID'
) }}

-- Define derived metrics as a macro variable for reusability
{% set derived_metrics = [
    'Gross Profit',
    'Gross Margin',
    'EBITDA',
    'EBITDA Margin',
    'Field EBITDA',
    'Field EBITDA Margin',
    'Post Corporate EBITDA',
    'Post Corporate EBITDA Margin',
    'Net Income',
    'Adjusted EBITDA',
    'Addbacks',
    'Total Liabilities & Equity'
] %}

with source as (
    select
        CAST(BUDGET.ID AS INT) AS  BUDGET_ID,
        BUDGET.CATEGORY AS DIM_BUDGET_HEADER_ID,
        BUDGET.SUBSIDIARY AS DIM_SUBSIDIARY_ID,
        BUDGET.ACCOUNT AS ACCOUNT_ID,
        BUDGET.CLASS AS DIM_CLASS_ID,
        BUDGET.DEPARTMENT AS DIM_DEPARTMENT_ID,
        BUDGET.LOCATION AS DIM_LOCATION_ID,
        BUDGET.PERIOD AS DIM_PERIOD_ID,
        DATE(per.STARTDATE) AS PERIOD_START_DATE,
        BUDGET.CURRENCY AS DIM_CURRENCY_ID,
        CAST(BUDGET.CUSTOMER AS INT) AS CUSTOMER_ID,
        CAST(BUDGET.ITEM AS INT) AS DIM_ITEM_ID,
        BUDGET.CSEG1 AS CSEG1_ID,
        BUDGET.CSEG3 AS CSEG3_ID,
        -- Derived Dimension Hashes
        ABS(HASH(BUDGET.ACCOUNT, BUDGET.SUBSIDIARY)) AS DIM_CHART_OF_ACCOUNT_ID,
        CAST(NULL AS INT) AS DIM_PROJECT_ID,
        map.METRIC_L1,
        map.METRIC_L2,
        map.METRIC_L3,
        map.METRIC_L4,
        map.METRIC_L5,
        map.METRIC_L6,
        BUDGET.AMOUNT, 
        
        -- Metadata
        BUDGET.LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,


    from {{ get_silver_source(company, 'BUDGETLEGACY') }} AS BUDGET
    LEFT JOIN {{ get_silver_source(company, company ~ '_COA_MAPPING') }} map
        ON ABS(HASH(BUDGET.ACCOUNT, BUDGET.SUBSIDIARY)) = ABS(HASH(map.ACCOUNT_ID, map.SUBSIDIARY_ID))
    LEFT JOIN {{ get_silver_source(company, 'ACCOUNTINGPERIOD') }} per 
        ON BUDGET.PERIOD = per.ID
   
    {% if is_incremental() %}
      and BUDGET.LASTMODIFIEDDATE > (
          select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
          from {{ this }}
      )
    {% endif %}
),
-- Create derived metric rows
derived_metric_rows as (
    {% for metric in derived_metrics %}
    SELECT
        CAST({{ -loop.index }} AS VARCHAR) AS BUDGET_ID,  -- Negative integers for uniqueness
        NULL AS DIM_BUDGET_HEADER_ID,
        NULL AS DIM_SUBSIDIARY_ID,
        NULL AS ACCOUNT_ID,
        NULL AS DIM_CLASS_ID,
        NULL AS DIM_DEPARTMENT_ID,
        NULL AS DIM_LOCATION_ID,
        NULL AS DIM_PERIOD_ID,
        NULL AS PERIOD_START_DATE,
        NULL AS DIM_CURRENCY_ID,
        NULL AS CUSTOMER_ID,
        NULL AS DIM_ITEM_ID,
        NULL AS CSEG1_ID,
        NULL AS CSEG3_ID,
        NULL AS DIM_CHART_OF_ACCOUNT_ID,
        NULL AS DIM_PROJECT_ID,
        '{{ metric }}' AS METRIC_L1,  -- Only METRIC_L1 is populated with the derived metric name
        NULL AS METRIC_L2,
        NULL AS METRIC_L3,
        NULL AS METRIC_L4,
        NULL AS METRIC_L5,
        NULL AS METRIC_L6,
        NULL AS AMOUNT,
        NULL AS LAST_MODIFIED_DATE,


    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
),

-- Final union of actual data and derived metrics
final_result as (
    SELECT * FROM source
    UNION ALL
    SELECT * FROM derived_metric_rows
)

select *
from final_result
