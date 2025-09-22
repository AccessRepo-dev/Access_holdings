{{ config(
    materialized = 'incremental',
    alias = 'dim_chart_of_account',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CHART_OF_ACCOUNT_ID'
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY'), "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY'), "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS'), "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH'), "source": "SAGE"}
] %}

{% for c in companies %}
    select
        ABS(HASH(DIM_CHART_OF_ACCOUNT_ID, '{{ c.name }}','{{c.source}}')) as DIM_CHART_OF_ACCOUNT_ID,
        DIM_CHART_OF_ACCOUNT_ID AS ACCOUNT_ID,
        ACCOUNT_NUMBER,
        ACCOUNT_NAME,
        MAIN_ACCOUNT_NAME,
        ACCOUNT_NAME_SUBCATEGORY_1,
        ACCOUNT_NAME_SUBCATEGORY_2,
        ACCOUNT_NAME_SUBCATEGORY_3,
        ACCOUNT_DESCRIPTION,
        ACCOUNT_PARENT_ID,
        ACCOUNT_TYPE,
        DISPLAY_NAME,
        DISPLAY_NAME_WITH_HIERARCHY,
        SUBSIDIARY_ID,
        SUBSIDIARY_PARENT_ID,
        SUBSIDIARY_NAME,
        SUBSIDIARY_FULL_NAME,
        DIM_CURRENCY_ID,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.GOLD.DIM_CHART_OF_ACCOUNT

    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
        where SOURCESYSTEM = '{{ c.source }}' and COMPANY = '{{ c.name }}'
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
