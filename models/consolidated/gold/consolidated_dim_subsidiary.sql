{{ config(
    materialized = 'incremental',
    alias = 'dim_subsidiary',
    incremental_strategy = 'merge',
    unique_key = ['DIM_SUBSIDIARY_ID']
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY'),  "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY'),"source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS'),  "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH'), "source": "SAGE"}
] %}

{% for c in companies %}
    select
        HASH(DIM_SUBSIDIARY_ID, '{{ c.name }}','{{ c.source }}' ) as DIM_SUBSIDIARY_ID,
        DIM_SUBSIDIARY_ID as SUBSIDIARY_ID,
        SUBSIDIARY_NAME,
        CURRENCY_ID,
        IS_INACTIVE,
        PARENT_ID,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.GOLD.DIM_SUBSIDIARY

    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
        where SOURCESYSTEM = '{{ c.source }}' and COMPANY = '{{ c.name }}'
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
