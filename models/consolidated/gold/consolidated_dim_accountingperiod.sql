{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['POSTING_PERIOD_ID','SOURCESYSTEM','COMPANY']
) }}

select
    POSTING_PERIOD_ID,
    PERIOD_NAME,
    START_DATE,
    END_DATE,
    CLOSED_ON_DATE,
    LAST_MODIFIED_DATE,
    YEAR,
    'NETSUITE' as sourcesystem,
    'WAGWAY' as company,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ env_var('DBT_WAGWAY', 'wagway_dev') }}.gold.NETSUITE_DIM_ACCOUNTING_PERIOD

union all

select
    POSTING_PERIOD_ID,
    PERIOD_NAME,
    START_DATE,
    END_DATE,
    CLOSED_ON_DATE,
    LAST_MODIFIED_DATE,
    YEAR,
    'NETSUITE' as sourcesystem,
    'PLAYFLY' as company,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ env_var('DBT_PLAYFLY', 'playfly_dev') }}.gold.NETSUITE_DIM_ACCOUNTING_PERIOD

union all

select
    REPORTING_PERIOD_ID AS POSTING_PERIOD_ID,
    PERIOD_NAME,
    START_DATE,
    END_DATE,
    NULL AS CLOSED_ON_DATE,
    LAST_MODIFIED_DATE,
    NULL YEAR,
    'SAGE' as sourcesystem,
    'SPOTLESS' as company,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ env_var('DBT_SPOTLESS', 'spotless_dev') }}.gold.SAGE_DIM_REPORTING_PERIOD

union all

select
    REPORTING_PERIOD_ID AS POSTING_PERIOD_ID,
    PERIOD_NAME,
    START_DATE,
    END_DATE,
    NULL AS CLOSED_ON_DATE,
    LAST_MODIFIED_DATE,
    NULL YEAR,
    'SAGE' as sourcesystem,
    'AMH' as company,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ env_var('DBT_AMH', 'amh_dev') }}.gold.SAGE_DIM_REPORTING_PERIOD

