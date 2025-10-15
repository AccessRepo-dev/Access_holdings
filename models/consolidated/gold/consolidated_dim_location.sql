{{ config(
    materialized = 'incremental',
    alias = 'dim_location',
    incremental_strategy = 'merge',
    unique_key = ['DIM_LOCATION_ID']
) }}

{% set companies = var('companies') %}

{% for c in companies %}
    select
        HASH(DIM_LOCATION_ID, '{{ c.name }}','{{ c.source }}') AS DIM_LOCATION_ID,
        DIM_LOCATION_ID AS LOCATION_ID,
        LOCATION_NAME,
        PARENT,
        SUBSIDIARY_ID,
        IS_INACTIVE,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' AS SOURCESYSTEM,
        '{{ c.name }}'   AS COMPANY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
    from  {{ render(c.db) }}.GOLD.DIM_LOCATION

    {% if is_incremental() %}
    WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
            where SOURCESYSTEM = '{{ c.source }}' and COMPANY = '{{ c.name }}'
        )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
