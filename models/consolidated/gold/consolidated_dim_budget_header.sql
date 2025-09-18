{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['DIM_BUDGET_HEADER_ID','SOURCESYSTEM','COMPANY']
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY', 'wagway_dev'),   "schema": "gold", "table": "NETSUITE_DIM_BUDGET_HEADER", "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY', 'playfly_dev'), "schema": "gold", "table": "NETSUITE_DIM_BUDGET_HEADER", "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS', 'spotless_dev'), "schema": "gold", "table": "SAGE_DIM_BUDGET_HEADER", "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH', 'amh_dev'),         "schema": "gold", "table": "SAGE_DIM_BUDGET_HEADER", "source": "SAGE"}
] %}

{% for c in companies %}
    select
        HASH(DIM_BUDGET_HEADER_ID, '{{ c.name }}') as DIM_BUDGET_HEADER_SK,
        DIM_BUDGET_HEADER_ID,
        BUDGET_TYPE,
        NAME,
        IS_INACTIVE,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.{{ c.schema }}.{{ c.table }}

    {% if not loop.last %} union all {% endif %}
{% endfor %}
