{% set company = var('company', 'wagway') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite') | lower == 'netsuite') }}

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
             (HASH(BUDGET.ACCOUNT, BUDGET.SUBSIDIARY,BUDGET.CLASS,BUDGET.LOCATION,BUDGET.DEPARTMENT,0)) AS DIM_CHART_OF_ACCOUNT_ID, ---0 for adjustment
        {% endif %}
        CAST(NULL AS INT) AS DIM_PROJECT_ID,
        BUDGET.AMOUNT, 
       
        -- Metadata
        BUDGET.LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,


    from {{ ref('netsuite_budgetlegacy') }} AS BUDGET
    LEFT JOIN {{ ref('netsuite_accountingperiod') }} per 
        ON BUDGET.PERIOD = per.ID

    WHERE (BUDGET._FIVETRAN_DELETED = False or BUDGET._FIVETRAN_DELETED  IS NULL)
    {% if is_incremental() %}
      AND BUDGET.LASTMODIFIEDDATE > (
          select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
          from {{ this }}
      )
    {% endif %}
),
coa as 
(
    SELECT *,
    CASE 
        WHEN METRIC_L1 IN ('COGS', 'Operating Expenses', 'Field Corporate Expenses', 'Corporate Expenses', 'Amortization', 'Depreciation', 'Taxes') OR METRIC_L2 IN ('Interest Expense', 'Other Expense')
            THEN -1
        ELSE 1
    END AS TYPE 
    FROM 
    {{ ref('netsuite_dim_coa') }} coa 
    
        
)
select s.*,coa.TYPE , coa.TYPE * s.AMOUNT AS ACTUAL_AMOUNT
from source s
left join coa on coa.DIM_CHART_OF_ACCOUNT_ID = s.DIM_CHART_OF_ACCOUNT_ID 


