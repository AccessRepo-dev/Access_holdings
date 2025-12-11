{% set company = var('company', 'wagway') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite') | lower == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_budget_header'
) }}

with source as (
    select
        ID AS DIM_BUDGET_HEADER_ID,
        BUDGETTYPE AS BUDGET_TYPE,
        NAME,
        NAME  AS GROUPED_HEADER,
        
        ISINACTIVE AS IS_INACTIVE
         
    from {{ref('netsuite_budgetcategory')}}
    WHERE (_FIVETRAN_DELETED = FALSE OR _FIVETRAN_DELETED IS NULL) 
)

select *
from source
UNION 
SELECT -1 AS ID , 
NULL AS BUDGET_TYPE, 
'Previous Year' AS NAME ,
'Previous Year' AS GROUPED_HEADER ,  
FALSE AS IS_INACTIVE 
