{{ config(
    alias = 'dim_employee',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_EMPLOYEE_ID'
) }}

{% set companies = var('companies') %}


{% for c in companies %}
select
    HASH(DIM_EMPLOYEE_ID, '{{ c.name }}','{{c.source}}') AS DIM_EMPLOYEE_ID,
    DIM_EMPLOYEE_ID AS EMPLOYEE_ID,
    TITLE,
    EMAIL,
    DEPARTMENT_ID,
    CLASS_ID,
    LOCATION_ID,
    SUBSIDIARY_ID,
    IS_INACTIVE,
    DATE_CREATED,
    LAST_MODIFIED_DATE,
    '{{ c.source }}' AS SOURCESYSTEM,
    '{{ c.name }}' AS COMPANY,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ render(c.db) }}.GOLD.DIM_EMPLOYEE
{% if not loop.last %} union all {% endif %}
{% endfor %}
