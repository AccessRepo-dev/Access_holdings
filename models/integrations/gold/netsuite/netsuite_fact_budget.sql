{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') | lower == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'fact_budget',
    incremental_strategy = 'merge',
    unique_key = 'BUDGET_ID'
) }}



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
        BUDGET.CSEG1 AS ADJUSTMENT_ID,
        BUDGET.CSEG3 AS CSEG3_ID,
        -- Derived Dimension Hashes
         {% if company == 'wagway' %}
            (HASH(BUDGET.ACCOUNT, BUDGET.SUBSIDIARY,BUDGET.CLASS,BUDGET.LOCATION,BUDGET.DEPARTMENT,BUDGET.CSEG1)) AS DIM_CHART_OF_ACCOUNT_ID,
        {% else %}
             (HASH(BUDGET.ACCOUNT, BUDGET.SUBSIDIARY,BUDGET.CLASS,BUDGET.LOCATION,BUDGET.DEPARTMENT)) AS DIM_CHART_OF_ACCOUNT_ID,
        {% endif %}
        CAST(NULL AS INT) AS DIM_PROJECT_ID,
        BUDGET.AMOUNT, 
        
        -- Metadata
        BUDGET.LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,


    from {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_BUDGETLEGACY') }} AS BUDGET
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_ACCOUNTINGPERIOD') }} per 
        ON BUDGET.PERIOD = per.ID
   
    {% if is_incremental() %}
      where BUDGET.LASTMODIFIEDDATE > (
          select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
          from {{ this }}
      )
    {% endif %}
)

select *
from source
