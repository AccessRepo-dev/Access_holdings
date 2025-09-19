{{ config(
    materialized = 'incremental',
    alias = 'dim_class',
    incremental_strategy = 'merge',
    unique_key = ['DIM_CLASS_ID']
) }}


{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY'),  "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY'),"source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS'),"source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH'), "source": "SAGE"}
] %}

{% for c in companies %}
    select
        HASH(DIM_CLASS_ID, '{{ c.name }}','{{ c.source }}') AS DIM_CLASS_ID,
        CLASS_ID,
        NAME,
        FULLNAME,
        PARENT_ID,
        IS_INACTIVE,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' AS SOURCESYSTEM,
        '{{ c.name }}' AS COMPANY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.GOLD.DIM_CLASS
    {% if not loop.last %} union all {% endif %}
{% endfor %}
