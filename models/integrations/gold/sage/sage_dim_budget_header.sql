{% set company = var('company', 'spotless') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}

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
    from  {{ref('sage_gl_budget_header')}}
    
    {% if is_incremental() %}
    where WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source
