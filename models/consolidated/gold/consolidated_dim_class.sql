{{ config(
    materialized = 'incremental',
    alias = 'dim_class',
    incremental_strategy = 'merge',
    unique_key = ['DIM_CLASS_ID']
) }}


{% set companies = var('companies') %}

{% for c in companies %}
    select
        HASH(DIM_CLASS_ID, '{{ c.name }}','{{ c.source }}') AS DIM_CLASS_ID,
        CLASS_ID,
        NAME,
        FULLNAME,
        PARENT_ID,
        IS_INACTIVE,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' AS SOURCESYSTEM,
        '{{ c.name }}' AS COMPANY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
    from {{ render(c.db) }}.GOLD.DIM_CLASS
    {% if not loop.last %} union all {% endif %}
{% endfor %}
