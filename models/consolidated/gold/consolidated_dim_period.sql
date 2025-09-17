{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['PERIOD_ID','SOURCESYSTEM','COMPANY']
) }}

select
    DIM_PERIOD_ID,
    PERIOD_NAME,
    START_DATE,
    END_DATE,
    CLOSED_ON_DATE,
    IS_INACTIVE,
    LAST_MODIFIED_DATE,
    'NETSUITE' as sourcesystem,
    'WAGWAY' as company,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ env_var('DBT_WAGWAY', 'wagway_dev') }}.gold.NETSUITE_DIM_PERIOD

union all

select
    DIM_PERIOD_ID,
    PERIOD_NAME,
    START_DATE,
    END_DATE,
    CLOSED_ON_DATE,
    IS_INACTIVE,
    LAST_MODIFIED_DATE,
    'NETSUITE' as sourcesystem,
    'PLAYFLY' as company,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ env_var('DBT_PLAYFLY', 'playfly_dev') }}.gold.NETSUITE_DIM_PERIOD

union all

select
    DIM_PERIOD_ID ,
    PERIOD_NAME,
    START_DATE,
    END_DATE,
    CLOSED_ON_DATE,
    IS_INACTIVE,
    LAST_MODIFIED_DATE,
    'SAGE' as sourcesystem,
    'SPOTLESS' as company,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ env_var('DBT_SPOTLESS', 'spotless_dev') }}.gold.SAGE_DIM_PERIOD

union all

select
    DIM_PERIOD_ID,
    PERIOD_NAME,
    START_DATE,
    END_DATE,
    CLOSED_ON_DATE,
    IS_INACTIVE,
    LAST_MODIFIED_DATE,
    'SAGE' as sourcesystem,
    'AMH' as company,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ env_var('DBT_AMH', 'amh_dev') }}.gold.SAGE_DIM_PERIOD

