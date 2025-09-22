{{ config(
    materialized = 'incremental',
    alias = 'dim_entity',
    incremental_strategy = 'merge',
    unique_key = 'DIM_ENTITY_ID'
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY'), "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY'), "source": "NETSUITE"}
] %}

{% for c in companies %}
    select
        ABS(HASH(DIM_ENTITY_ID, '{{ c.name }}','{{c.source}}')) as DIM_ENTITY_ID,
        DIM_ENTITY_ID AS ENTITY_ID,
        ENTITY_ID AS INTERNAL_ENTITY_ID,
        ENTITY_NUMBER,
        ENTITY_TITLE,
        FIRST_NAME,
        LAST_NAME,
        ENTITY_TYPE,
        IS_PERSON,
        CONTACT_ID,
        EMPLOYEE_ID,
        CUSTOMER_ID,
        DATE_CREATED,
        EMAIL,
        GROUP_ID,
        IS_INACTIVE,
        LAST_MODIFIED_DATE,
        PARENT_ID,
        VENDOR_ID,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.GOLD.DIM_ENTITY

    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
        where SOURCESYSTEM = '{{ c.source }}' and COMPANY = '{{ c.name }}'
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
