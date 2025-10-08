{{ config(
    materialized = 'incremental',
    alias = 'dim_period_flag',
    incremental_strategy = 'merge',
    unique_key = 'DIM_PERIOD_ID'
) }}


{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY'), "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY'),  "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS'), "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH'), "source": "SAGE"}
] %}

{% for c in companies %}
    select
        HASH(DIM_PERIOD_ID,FLAG_TYPE, '{{ c.name }}','{{ c.source }}') AS DIM_PERIOD_ID,
        DIM_PERIOD_ID AS PERIOD_ID,
        START_DATE,
        FLAG_TYPE,
        '{{ c.source }}' AS SOURCESYSTEM,
        '{{ c.name }}' AS COMPANY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.GOLD.DIM_PERIOD_FLAG
    {% if not loop.last %} union all {% endif %}
{% endfor %}
