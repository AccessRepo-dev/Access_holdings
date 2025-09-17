{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['DIM_BUDGET_HEADER_ID','COMPANY']
) }}

select
    DIM_BUDGET_HEADER_ID,
    BUDGET_TYPE,
    NAME,
    IS_INACTIVE,
    'wagway' as company
from {{ env_var('DBT_WAGWAY', 'wagway_dev') }}.gold.NETSUITE_DIM_BUDGET_HEADER
-- where
--     {% if is_incremental() %}
--     LAST_MODIFIED_DATE > (
--         select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
--         from {{ this }}
--     )
--     {% else %} 1=1 {% endif %}

union all

select
    DIM_BUDGET_HEADER_ID,
    BUDGET_TYPE,
    NAME,
    IS_INACTIVE,
    'playfly' as company
from {{ env_var('DBT_PLAYFLY', 'playfly_dev') }}.gold.NETSUITE_DIM_BUDGET_HEADER
-- where
--     {% if is_incremental() %}
--     LAST_MODIFIED_DATE > (
--         select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
--         from {{ this }}
--     )
--     {% else %} 1=1 {% endif %}

union all

select
    DIM_BUDGET_HEADER_ID,
    BUDGET_TYPE,
    NAME,
    IS_INACTIVE,
    'spotless' as company
from {{ env_var('DBT_SPOTLESS', 'spotless_dev') }}.gold.SAGE_DIM_BUDGET_HEADER

union all

select
    DIM_BUDGET_HEADER_ID,
    BUDGET_TYPE,
    NAME,
    IS_INACTIVE,
    'amh' as company
from {{ env_var('DBT_AMH', 'amh_dev') }}.gold.SAGE_DIM_BUDGET_HEADER
