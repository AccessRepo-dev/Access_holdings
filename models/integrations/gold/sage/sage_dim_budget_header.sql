{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_BUDGET_CATEGORY_ID'
) }}

with source as (
    select
        RECORDNO AS DIM_BUDGET_HEADER_ID,
        NULL AS BUDGET_TYPE,
        DESCRIPTION AS NAME,
        STATUS AS IS_INACTIVE,
        WHENMODIFIED AS LAST_MODIFIED_DATE
    from {{ get_silver_source(company, 'sage_gl_budget_header') }}
    
    {% if is_incremental() %}
    where WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source
