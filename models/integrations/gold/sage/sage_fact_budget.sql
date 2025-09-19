{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'fact_budget',
    materialized = 'incremental',
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
    'Net Income'
] %}

with source as (
    select
        RECORDNO AS BUDGET_ID,
        BUDGETKEY AS DIM_BUDGET_HEADER_ID,
        b.LOCATIONKEY AS DIM_SUBSIDIARY_ID,       
        b.ACCOUNTKEY AS ACCOUNT_ID,
        b.CLASSDIMKEY AS CLASS_ID,           
        b.DEPTKEY AS DIM_DEPARTMENT_ID,
        b.LOCATIONKEY AS DIM_LOCATION_ID,
        b.PERIODKEY AS DIM_PERIOD_ID,
        NULL AS DIM_CURRENCY_ID,         
        NULL AS CUSTOMER_ID,
        NULL AS ITEM_ID,
        NULL AS CSEG1_ID,               
        NULL AS CSEG3_ID,

        -- Derived Dimension Hashes (for conformed COA / Class across subs)
        ABS(HASH(b.ACCOUNTKEY, b.LOCATIONKEY)) AS DIM_CHART_OF_ACCOUNT_ID,
        ABS(HASH(b.CLASSDIMKEY, b.LOCATIONKEY)) AS DIM_CLASS_ID,

        -- Measure
        b.AMOUNT AS AMOUNT,
        map.METRIC_L1,
        map.METRIC_L2,
        map.METRIC_L3,
        map.METRIC_L4,
        map.METRIC_L5,
        CAST(map.METRIC_L6 AS VARCHAR) AS METRIC_L6, 
        -- Metadata
        b.WHENMODIFIED AS LAST_MODIFIED_DATE

FROM {{ get_silver_source(company, 'GL_BUDGET_ITEM') }} b
LEFT JOIN {{ get_silver_source(company, 'SAGE_COA_MAPPING') }} map
    ON ABS(HASH(b.ACCOUNTKEY, b.LOCATIONKEY)) = ABS(HASH(map.ACCOUNT_ID, map.LOCATION_ID))

    {% if is_incremental() %}
    where WHENMODIFIED > (
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
        NULL AS CLASS_ID,
        NULL AS DIM_DEPARTMENT_ID,
        NULL AS DIM_LOCATION_ID,
        NULL AS DIM_PERIOD_ID,
        NULL AS DIM_CURRENCY_ID,
        NULL AS DIM_CUSTOMER_ID,
        NULL AS ITEM_ID,
        NULL AS CSEG1_ID,
        NULL AS CSEG3_ID,
        NULL AS DIM_CHART_OF_ACCOUNT_ID,
        NULL AS DIM_CLASS_ID,
        NULL AS AMOUNT,
        '{{ metric }}' AS METRIC_L1,  -- Only METRIC_L1 is populated with the derived metric name
        NULL AS METRIC_L2,
        NULL AS METRIC_L3,
        NULL AS METRIC_L4,
        NULL AS METRIC_L5,
        NULL AS METRIC_L6,
        
        NULL AS LASTMODIFIEDDATE
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

SELECT * FROM final_result
