{{ config(
    materialized = 'table'
) }}

select
    *,
    'wagway' as company
from {{ env_var('DBT_WAGWAY', 'wagway_dev') }}.gold.NETSUITE_FACT_TRANSACTION


union all

select
    *,
    'playfly' as company
from {{ env_var('DBT_PLAYFLY', 'playfly_dev') }}.gold.NETSUITE_FACT_TRANSACTION
