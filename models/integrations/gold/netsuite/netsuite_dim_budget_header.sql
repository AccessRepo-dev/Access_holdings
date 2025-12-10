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
        {% if company == 'playfly'%}
        CASE 
            WHEN NAME = 'SOH Canada'
            THEN 'Budget' ELSE  NAME 
        END AS GROUPED_HEADER 
        {%else%}
        NAME AS GROUPED_HEADER 
        {%endif%}
        ISINACTIVE AS IS_INACTIVE
         
    from {{ref('netsuite_budgetcategory')}}
    WHERE (_FIVETRAN_DELETED = FALSE OR _FIVETRAN_DELETED IS NULL) 
)

select *
from source
