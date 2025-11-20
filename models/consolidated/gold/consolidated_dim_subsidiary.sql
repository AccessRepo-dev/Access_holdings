{{ config(
    materialized = 'incremental',
    alias = 'dim_subsidiary',
    incremental_strategy = 'merge',
    unique_key = ['DIM_SUBSIDIARY_ID']
) }}

{% set companies = var('companies') %}

{% for c in companies %}
    select
        HASH(DIM_SUBSIDIARY_ID, '{{ c.name }}','{{ c.source }}' ) as DIM_SUBSIDIARY_ID,
        DIM_SUBSIDIARY_ID as SUBSIDIARY_ID,
        SUBSIDIARY_NAME,
        SUBSIDIARY_FULL_NAME,
        PARENT_NAME,
        CHILD_NAME,
        CURRENCY_ID,
        DIVISION_MAPPING,
        IS_INACTIVE,
        PARENT_ID,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ render(c.db) }}.GOLD.DIM_SUBSIDIARY

    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
        where SOURCESYSTEM = '{{ c.source }}' and COMPANY = '{{ c.name }}'
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
