{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['DIM_ACCOUNT_ID','COMPANY']
) }}

select
    *,
    'wagway' as company
from {{ env_var('DBT_WAGWAY', 'wagway_dev') }}.gold.NETSUITE_DIM_CHART_OF_ACCOUNT

union all

select
    *,
    'playfly' as company
from {{ env_var('DBT_PLAYFLY', 'playfly_dev') }}.gold.NETSUITE_DIM_CHART_OF_ACCOUNT

