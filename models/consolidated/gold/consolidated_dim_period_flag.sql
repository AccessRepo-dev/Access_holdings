{{ config(
    materialized = 'incremental',
    alias = 'dim_period_flag',
    incremental_strategy = 'merge',
    unique_key = 'DIM_PERIOD_ID'
) }}


{% set companies = var('companies') %}

{% for c in companies if c.name %}
    select
        HASH(DIM_PERIOD_ID,FLAG_TYPE,START_DATE ,'{{ c.name }}','{{ c.source }}') AS DIM_PERIOD_ID,
        DIM_PERIOD_ID AS PERIOD_ID,
        START_DATE,
        FLAG_TYPE,
        '{{ c.source }}' AS SOURCESYSTEM,
        '{{ c.name }}' AS COMPANY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
    from {{ render(c.db) }}.GOLD.DIM_PERIOD_FLAG
    {% if not loop.last %} union all {% endif %}
{% endfor %}
