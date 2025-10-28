{{ config(
    materialized = 'incremental',
    alias = 'dim_department',
    incremental_strategy = 'merge',
    unique_key = 'DIM_DEPARTMENT_ID'
) }}

{% set companies = var('companies') %}

{% for c in companies if c.name | lower != 'zeus' %}
    select
        HASH(DIM_DEPARTMENT_ID, '{{ c.name }}','{{c.source}}') AS DIM_DEPARTMENT_ID,
        DIM_DEPARTMENT_ID AS DEPARTMENT_ID,
        DEPARTMENT_NAME,
        PARENT,
        IS_INACTIVE,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' AS SOURCESYSTEM,
        '{{ c.name }}' AS COMPANY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
    from {{ render(c.db) }}.GOLD.DIM_DEPARTMENT

    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }} 
        WHERE SOURCESYSTEM = '{{ c.source }}' AND COMPANY = '{{ c.name }}' 
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
