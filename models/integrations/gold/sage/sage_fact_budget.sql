{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'BUDGET_ID'
) }}

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

        -- Metadata
        b.WHENMODIFIED AS LAST_MODIFIED_DATE

FROM {{ get_silver_source(company, 'sage_gl_budget_item') }} b

    {% if is_incremental() %}
    where WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source
