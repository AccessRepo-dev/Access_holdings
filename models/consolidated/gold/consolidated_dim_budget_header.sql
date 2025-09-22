{{ config(
    materialized = 'incremental',
    alias = 'dim_budget_header',
    incremental_strategy = 'merge',
    unique_key = 'DIM_BUDGET_HEADER_ID'
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY'), "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY'), "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS'),"source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH'),"source": "SAGE"}
] %}

{% for c in companies %}
    select
        HASH(DIM_BUDGET_HEADER_ID, '{{ c.name }}','{{c.source}}') as DIM_BUDGET_HEADER_ID,
        DIM_BUDGET_HEADER_ID AS BUDGET_HEADER_ID,
        BUDGET_TYPE,
        NAME,
        IS_INACTIVE,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.GOLD.DIM_BUDGET_HEADER

    {% if not loop.last %} union all {% endif %}
{% endfor %}
