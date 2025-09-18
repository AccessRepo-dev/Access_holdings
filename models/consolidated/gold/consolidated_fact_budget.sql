{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['BUDGET_ID','SOURCESYSTEM','COMPANY']
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY', 'wagway_dev'),   "schema": "gold", "table": "NETSUITE_FACT_BUDGET", "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY', 'playfly_dev'), "schema": "gold", "table": "NETSUITE_FACT_BUDGET", "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS', 'spotless_dev'), "schema": "gold", "table": "SAGE_FACT_BUDGET", "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH', 'amh_dev'),         "schema": "gold", "table": "SAGE_FACT_BUDGET", "source": "SAGE"}
] %}

{% for c in companies %}
    select
        HASH(BUDGET_ID, '{{ c.name }}') as FACT_BUDGET_ID,
        BUDGET_ID,
        DIM_BUDGET_HEADER_ID,
        DIM_SUBSIDIARY_ID,
        ACCOUNT_ID,
        CLASS_ID,
        DIM_DEPARTMENT_ID,
        DIM_LOCATION_ID,
        DIM_PERIOD_ID,
        DIM_CURRENCY_ID,
        CUSTOMER_ID,
        ITEM_ID,
        CSEG1_ID,
        CSEG3_ID,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.{{ c.schema }}.{{ c.table }}

    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
        where SOURCESYSTEM = '{{ c.source }}' and COMPANY = '{{ c.name }}'
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
