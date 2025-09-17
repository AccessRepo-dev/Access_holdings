
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DEPARTMENT_ID'
) }}

with source as (
    select
        RECORDNO AS DIM_DEPARTMENT_ID,
        TITLE AS DEPARTMENT_NAME,
        PARENTKEY AS PARENT,
        STATUS AS IS_INACTIVE,
        WHENMODIFIED AS LAST_MODIFIED_DATE
    from {{ get_silver_source(company, 'sage_department') }}
    
    {% if is_incremental() %}
    and WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source 