{{ config(
    materialized = 'incremental',
    alias = 'dim_chart_of_account',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CHART_OF_ACCOUNT_ID'
) }}

{% set companies = var('companies') %}

{% for c in companies %}
    select
        (HASH(DIM_CHART_OF_ACCOUNT_ID, '{{ c.name }}','{{c.source}}')) as DIM_CHART_OF_ACCOUNT_ID,
        DIM_CHART_OF_ACCOUNT_ID AS ACCOUNT_ID,
        ACCOUNT_NAME,
        ACCOUNT_NUMBER,
        SUBSIDIARY_ID,
        SUBSIDIARY_NAME,
        CLASS_ID,
        CLASS_NAME,
        PROJECT_ID,
        PROJECT_NAME,
        DEPARTMENT_ID,
        DEPARTMENT_NAME,
        LOCATION_ID,
        LOCATION_NAME,
        METRIC_L1,
        METRIC_L2,
        METRIC_L3,
        METRIC_L4,
        METRIC_L5,
        METRIC_L6,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ render(c.db) }}.GOLD.DIM_CHART_OF_ACCOUNT
    {% if not loop.last %} union all {% endif %}
{% endfor %}
