{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
) }}

with source as (
    select
        ID AS DIM_BUDGET_CATEGORY_ID,
        BUDGETTYPE AS BUDGET_TYPE,
        ISINACTIVE AS IS_INACTIVE,
        NAME
    from {{ get_silver_source(company, 'netsuite_budgetcategory') }}
   
)

select *
from source
