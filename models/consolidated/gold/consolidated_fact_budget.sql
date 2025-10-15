{{ config(
    materialized = 'incremental',
    alias = 'fact_budget',
    incremental_strategy = 'merge',
    unique_key = 'FACT_BUDGET_ID'
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
        HASH(DIM_SUBSIDIARY_ID, '{{ c.name }}',  '{{ c.source }}') as  DIM_SUBSIDIARY_ID,
        ACCOUNT_ID,
        HASH(DIM_CLASS_ID, '{{ c.name }}',  '{{ c.source }}') as DIM_CLASS_ID,
        HASH(DIM_DEPARTMENT_ID, '{{ c.name }}',  '{{ c.source }}') as DIM_DEPARTMENT_ID,
        HASH(DIM_LOCATION_ID, '{{ c.name }}',  '{{ c.source }}') as DIM_LOCATION_ID,
        HASH(DIM_PERIOD_ID, '{{ c.name }}',  '{{ c.source }}') as DIM_PERIOD_ID,
        PERIOD_START_DATE,
        HASH(DIM_CURRENCY_ID, '{{ c.name }}',  '{{ c.source }}') as DIM_CURRENCY_ID,
        CUSTOMER_ID,
        HASH(DIM_ITEM_ID, '{{ c.name }}',  '{{ c.source }}') as DIM_ITEM_ID,
        CSEG1_ID,
        CSEG3_ID,
        HASH(DIM_CHART_OF_ACCOUNT_ID, '{{ c.name }}',  '{{ c.source }}') as DIM_CHART_OF_ACCOUNT_ID,
        HASH(DIM_PROJECT_ID, '{{ c.name }}',  '{{ c.source }}') as DIM_PROJECT_ID,
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
