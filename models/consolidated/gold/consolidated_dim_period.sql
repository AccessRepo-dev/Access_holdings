{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['DIM_PERIOD_ID','SOURCESYSTEM','COMPANY']
) }}


{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY', 'wagway_dev'),   "schema": "gold", "table": "NETSUITE_DIM_PERIOD", "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY', 'playfly_dev'), "schema": "gold", "table": "NETSUITE_DIM_PERIOD", "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS', 'spotless_dev'), "schema": "gold", "table": "SAGE_DIM_PERIOD", "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH', 'amh_dev'),         "schema": "gold", "table": "SAGE_DIM_PERIOD", "source": "SAGE"}
] %}

{% for c in companies %}
    select
        HASH(DIM_PERIOD_ID, '{{ c.name }}') AS DIM_PERIOD_ID,
        DIM_PERIOD_ID AS PERIOD_ID,
        PERIOD_NAME,
        START_DATE,
        END_DATE,
        CLOSED_ON_DATE,
        IS_INACTIVE,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' AS SOURCESYSTEM,
        '{{ c.name }}' AS COMPANY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.{{ c.schema }}.{{ c.table }}

    {% if is_incremental() %}
    and LAST_MODIFIED_DATE > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }} 
        WHERE SOURCESYSTEM = '{{ c.source }}' AND COMPANY = '{{ c.name }}' 
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
