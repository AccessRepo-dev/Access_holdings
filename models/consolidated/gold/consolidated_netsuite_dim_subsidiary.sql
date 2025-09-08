{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['SUBSIDIARY_ID','COMPANY']
) }}

select
    *,
    'wagway' as company
from {{ env_var('DBT_WAGWAY', 'wagway_dev') }}.gold.NETSUITE_DIM_SUBSIDIARY
where
    {% if is_incremental() %}
    LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% else %} 1=1 {% endif %}

union all

select
    *,
    'playfly' as company
from {{ env_var('DBT_PLAYFLY', 'playfly_dev') }}.gold.NETSUITE_DIM_SUBSIDIARY
where
    {% if is_incremental() %}
    LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% else %} 1=1 {% endif %}
