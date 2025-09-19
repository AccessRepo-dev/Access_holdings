{{ config(
    materialized = 'incremental',
    alias ='dim_currency',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CURRENCY_ID'
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY'), "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY'), "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS'), "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH'), "source": "SAGE"}
] %}

{% for c in companies %}
    select
        ABS(HASH(DIM_CURRENCY_ID, '{{ c.name }}','{{c.source}}')) as DIM_CURRENCY_ID,
        DIM_CURRENCY_ID AS CURRNECY_ID,
        CURRENCY_NAME,
        DISPLAY_SYMBOL,
        IS_INACTIVE,
        IS_BASE_CURRENCY,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.GOLD.DIM_CURRENCY

    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
        where SOURCESYSTEM = '{{ c.source }}' and COMPANY = '{{ c.name }}'
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}