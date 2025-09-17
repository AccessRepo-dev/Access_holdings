{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['EMPLOYEE_ID','COMPANY']
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY', 'wagway_dev'),   "schema": "gold", "table": "NETSUITE_DIM_EMPLOYEE", "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY', 'playfly_dev'), "schema": "gold", "table": "NETSUITE_DIM_EMPLOYEE", "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS', 'spotless_dev'), "schema": "gold", "table": "SAGE_DIM_EMPLOYEE", "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH', 'amh_dev'),         "schema": "gold", "table": "SAGE_DIM_EMPLOYEE", "source": "SAGE"}
] %}


{% for c in companies %}
select
    HASH(DIM_EMPLOYEE_ID, '{{ c.name }}') AS DIM_EMPLOYEE_ID,
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
from {{ c.db }}.{{ c.schema }}.{{ c.table }}
{% if not loop.last %} union all {% endif %}
{% endfor %}
