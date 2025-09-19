{{ config(
    materialized = 'incremental',
    alias = 'dim_department',
    incremental_strategy = 'merge',
    unique_key = 'DIM_DEPARTMENT_ID'
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY'),"source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY'), "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS'), "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH'), "source": "SAGE"}
] %}

{% for c in companies %}
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
    from {{ c.db }}.GOLD.DIM_DEPARTMENT

    {% if is_incremental() %}
    and LAST_MODIFIED_DATE > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }} 
        WHERE SOURCESYSTEM = '{{ c.source }}' AND COMPANY = '{{ c.name }}' 
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
