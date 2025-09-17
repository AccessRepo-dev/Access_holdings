{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['BUDGET_ID','COMPANY']
) }}

select
    BUDGET_ID,
    DIM_BUDGET_HEADER_ID,
    DIM_SUBSIDIARY_ID,
    ACCOUNT_ID,
    CLASS_ID,
    DIM_DEPARTMENT_ID,
    DIM_LOCATION_ID,
    DIM_PERIOD_ID,
    DIM_CURRENCY_ID,
    CUSTOMER_ID,
    ITEM_ID,
    CSEG1_ID,
    CSEG3_ID,
    LAST_MODIFIED_DATE,
    'wagway' as company
from {{ env_var('DBT_WAGWAY', 'wagway_dev') }}.gold.NETSUITE_FACT_BUDGET
where
    {% if is_incremental() %}
    LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% else %} 1=1 {% endif %}

union all

select
    BUDGET_ID,
    DIM_BUDGET_HEADER_ID,
    DIM_SUBSIDIARY_ID,
    ACCOUNT_ID,
    CLASS_ID,
    DIM_DEPARTMENT_ID,
    DIM_LOCATION_ID,
    DIM_PERIOD_ID,
    DIM_CURRENCY_ID,
    CUSTOMER_ID,
    ITEM_ID,
    CSEG1_ID,
    CSEG3_ID,
    LAST_MODIFIED_DATE,
    'playfly' as company
from {{ env_var('DBT_PLAYFLY', 'playfly_dev') }}.gold.NETSUITE_FACT_BUDGET
where
    {% if is_incremental() %}
    LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% else %} 1=1 {% endif %}

union all

select
    BUDGET_ID,
    DIM_BUDGET_HEADER_ID,
    DIM_SUBSIDIARY_ID,
    ACCOUNT_ID,
    CLASS_ID,
    DIM_DEPARTMENT_ID,
    DIM_LOCATION_ID,
    DIM_PERIOD_ID,
    DIM_CURRENCY_ID,
    CUSTOMER_ID,
    ITEM_ID,
    CSEG1_ID,
    CSEG3_ID,
    LAST_MODIFIED_DATE,
    'spotless' as company
from {{ env_var('DBT_SPOTLESS', 'spotless_dev') }}.gold.SAGE_FACT_BUDGET
where
    {% if is_incremental() %}
    LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% else %} 1=1 {% endif %}

union all

select
    BUDGET_ID,
    DIM_BUDGET_HEADER_ID,
    DIM_SUBSIDIARY_ID,
    ACCOUNT_ID,
    CLASS_ID,
    DIM_DEPARTMENT_ID,
    DIM_LOCATION_ID,
    DIM_PERIOD_ID,
    DIM_CURRENCY_ID,
    CUSTOMER_ID,
    ITEM_ID,
    CSEG1_ID,
    CSEG3_ID,
    LAST_MODIFIED_DATE,
    'amh' as company
from {{ env_var('DBT_amh', 'amh_dev') }}.gold.SAGE_FACT_BUDGET
where
    {% if is_incremental() %}
    LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% else %} 1=1 {% endif %}
