{{ config(
    materialized = 'incremental',
    alias ='dim_currency',
    incremental_strategy = 'table'
) }}

{% set companies = var('companies') %}

{% for c in companies %}
    select
        HASH(DIM_PERIOD_ID, '{{ c.name }}','{{ c.source }}') AS DIM_PERIOD_ID,
        DIM_PERIOD_ID AS PERIOD_ID,
        HASH(FROM_SUBSIDIARY_ID, '{{ c.name }}','{{ c.source }}') AS FROM_SUBSIDIARY_ID,
        HASH(TO_SUBSIDIARY_ID, '{{ c.name }}','{{ c.source }}') AS TO_SUBSIDIARY_ID ,
        FROM_CURRENCY_ID,
        TO_CURRENCY_ID,
        HISTORICALRATE,
        AVERAGERATE,
        CURRENTRATE,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ render(c.db) }}.GOLD.DIM_CURRENCY
    {% if not loop.last %} union all {% endif %}
{% endfor %}