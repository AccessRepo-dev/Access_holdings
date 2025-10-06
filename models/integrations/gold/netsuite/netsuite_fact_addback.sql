{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'fact_addback',
) }}

with source as (
    select
    *
    from {{ get_silver_source(company, company ~ '_addbacks') }} AS BUDGET
    
)

select *
from source
