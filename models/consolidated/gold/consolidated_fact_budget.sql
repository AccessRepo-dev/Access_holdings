{{ config(
    materialized = 'incremental',
    alias = 'fact_budget',
    incremental_strategy = 'merge',
    unique_key = ['FACT_BUDGET_ID']
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY') , "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY'),  "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS'), "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH'),   "source": "SAGE"}
] %}

{% for c in companies %}
    select
        HASH(BUDGET_ID, '{{ c.name }}',  '{{ c.source }}') as FACT_BUDGET_ID,
        BUDGET_ID,
        DIM_BUDGET_HEADER_ID,
        DIM_SUBSIDIARY_ID,
        ACCOUNT_ID,
        DIM_CLASS_ID,
        DIM_DEPARTMENT_ID,
        DIM_LOCATION_ID,
        DIM_PERIOD_ID,
        PERIOD_START_DATE,
        DIM_CURRENCY_ID,
        CUSTOMER_ID,
        DIM_ITEM_ID,
        CSEG1_ID,
        CSEG3_ID,
        DIM_CHART_OF_ACCOUNT_ID,
        DIM_PROJECT_ID,
        METRIC_L1,
        METRIC_L2,
        METRIC_L3,
        METRIC_L4,
        METRIC_L5,
        METRIC_L6,
        AMOUNT,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.GOLD.FACT_BUDGET

    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
        where SOURCESYSTEM = '{{ c.source }}' and COMPANY = '{{ c.name }}'
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
