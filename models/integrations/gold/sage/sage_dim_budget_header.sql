{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    alias = 'dim_budget_header',
    unique_key = 'DIM_BUDGET_HEADER_ID'
) }}

with source as (
    select
        RECORDNO AS DIM_BUDGET_HEADER_ID,
        NULL AS BUDGET_TYPE,
        DESCRIPTION AS NAME,
        STATUS AS IS_INACTIVE,
        WHENMODIFIED AS LAST_MODIFIED_DATE
    from {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_GL_BUDGET_HEADER') }}
    
    {% if is_incremental() %}
    where WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source
