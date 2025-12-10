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
        BUDGETID AS BUDGET_TYPE,
        DESCRIPTION AS NAME,
        STATUS AS IS_INACTIVE,
       
    from  {{ref('sage_gl_budget_header')}}
    
    WHERE (_FIVETRAN_DELETED = FALSE OR _FIVETRAN_DELETED IS NULL) 
  
)
select *
from source
