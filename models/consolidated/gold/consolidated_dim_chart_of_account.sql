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
        CAST(ACCOUNT_NUMBER AS VARCHAR) AS ACCOUNT_NUMBER,
        SUBSIDIARY_ID,
        SUBSIDIARY_NAME,
        CASE WHEN '{{ c.name }}'='ZEUS' THEN CAST(CLASS_ID AS NUMBER) ELSE CLASS_ID END AS CLASS_ID,
        {% if c.name == 'ZEUS' %} CAST(NULL AS NUMBER) AS ADJUSTMENT_ID, {% else %} ADJUSTMENT_ID AS ADJUSTMENT_ID, {% endif %}
        CLASS_NAME,
        CASE WHEN '{{ c.name }}'='ZEUS' THEN CAST(PROJECT_ID AS NUMBER) ELSE PROJECT_ID END AS PROJECT_ID,
        PROJECT_NAME,
        CASE WHEN '{{ c.name }}'='ZEUS' THEN CAST(DEPARTMENT_ID AS NUMBER) ELSE DEPARTMENT_ID END AS DEPARTMENT_ID,
        DEPARTMENT_NAME,
        CASE WHEN '{{ c.name }}'='ZEUS' THEN CAST(LOCATION_ID AS NUMBER) ELSE LOCATION_ID END AS LOCATION_ID,
        LOCATION_NAME,
        METRIC_L1,
        METRIC_L2,
        METRIC_L3,
        METRIC_L4,
        METRIC_L5,
        METRIC_L6,
        CASH_FLOW_L1,
        CASH_FLOW_L2,
        CASH_FLOW_L3,
        IS_BS,
        DEBT_MAPPING,
        {% if c.name == 'ZEUS' %} CAST(NULL AS NUMBER) AS IS_ADJ, {% else %} IS_ADJ AS IS_ADJ, {% endif %}
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ render(c.db) }}.GOLD.DIM_CHART_OF_ACCOUNT
    {% if not loop.last %} union all {% endif %}
{% endfor %}
