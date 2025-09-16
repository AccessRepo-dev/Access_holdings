{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_BUDGET_CATEGORY_ID'
) }}

with source as (
    select
        BUDGETKEY AS BUDGET_ID,
        -- Core Dimensions
        SUBSIDIARY AS SUBSIDIARY_ID,
        ACCOUNT AS ACCOUNT_ID,
        CLASS AS CLASS_ID,
        CATEGORY AS CATEGORY_ID,
        DEPARTMENT AS DIM_DEPARTMENT_ID,
        LOCATION AS DIM_LOCATION_ID,
        PERIOD AS DIM_PERIOD_ID,
        CURRENCY AS DIM_CURRENCY_ID,
        CUSTOMER AS CUSTOMER_ID,
        ITEM AS ITEM_ID,
        CSEG1 AS CSEG1_ID,
        CSEG3 AS CSEG3_ID,
        
        -- Derived Dimension Hashes
        ABS(HASH(ACCOUNT, SUBSIDIARY)) AS DIM_CHART_OF_ACCOUNT_ID,
        ABS(HASH(CLASS, SUBSIDIARY)) AS DIM_CLASS_ID,
        
        -- Measure
        AMOUNT AS AMOUNT,
        
        -- Metadata
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE
    from {{ get_silver_source(company, 'sage_gl_budget_item') }}
    
    {% if is_incremental() %}
    where WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source
