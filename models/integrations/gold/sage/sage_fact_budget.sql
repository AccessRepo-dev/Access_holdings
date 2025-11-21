{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'fact_budget',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'BUDGET_ID'
) }}



with source as (
    select
        CAST(b.RECORDNO AS INT) AS BUDGET_ID,
        b.BUDGETKEY AS DIM_BUDGET_HEADER_ID,
        b.LOCATIONKEY AS DIM_SUBSIDIARY_ID,       
        b.ACCOUNTKEY AS ACCOUNT_ID,
        b.CLASSDIMKEY AS DIM_CLASS_ID,           
        b.DEPTKEY AS DIM_DEPARTMENT_ID,
        b.LOCATIONKEY AS DIM_LOCATION_ID,
        b.PERIODKEY AS DIM_PERIOD_ID,
        DATE(PSTARTDATE) AS PERIOD_START_DATE,
        CAST(NULL AS INT) AS DIM_CURRENCY_ID,         
        CAST(NULL AS INT) AS CUSTOMER_ID,
        CAST(NULL AS INT) AS DIM_ITEM_ID,
        CAST(NULL AS INT) AS ADJUSTMENT_ID,               
        CAST(NULL AS INT) AS CSEG3_ID,
        -- Derived Dimension Hashes (for conformed COA / Class across subs)
        (HASH(b.ACCOUNTKEY, b.LOCATIONKEY,b.DEPTKEY,b.PROJECTDIMKEY,b.CLASSDIMKEY)) AS DIM_CHART_OF_ACCOUNT_ID,
        b.PROJECTDIMKEY AS DIM_PROJECT_ID,
        b.AMOUNT AS AMOUNT,
        -- Metadata
        b.WHENMODIFIED AS LAST_MODIFIED_DATE

FROM {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_GL_BUDGET_ITEM') }} b


    {% if is_incremental() %}
    where b.WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)

SELECT * FROM source

