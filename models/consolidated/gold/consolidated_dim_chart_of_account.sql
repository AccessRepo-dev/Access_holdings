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
        DIM_SUBSIDIARY_ID,
        DIM_CURRENCY_ID,
        DIM_LOCATION_ID,
        DIM_DEPARTMENT_ID,
        DIM_PROJECT_ID,
        METRIC_L1,
        METRIC_L2,
        METRIC_L3,
        METRIC_L4,
        METRIC_L5,
        METRIC_L6,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.GOLD.DIM_CHART_OF_ACCOUNT_NEW
    {% if not loop.last %} union all {% endif %}
{% endfor %}
