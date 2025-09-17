{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
) }}

with source as (
    select
        ID AS DIM_BUDGET_HEADER_ID,
        BUDGETTYPE AS BUDGET_TYPE,
        NAME,
        ISINACTIVE AS IS_INACTIVE
         
    from {{ get_silver_source(company, 'netsuite_budgetcategory') }}
   
)

select *
from source
