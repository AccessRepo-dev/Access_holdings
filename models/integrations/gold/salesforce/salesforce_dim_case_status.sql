{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table'
) }}

with source as (

    select
        DISTINCT    
        STATUS,
        IS_CLOSED
    from {{ get_silver_source(company, 'SALESFORCE_CASE') }}

    {% if is_incremental() %}
        WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}
)
select *
from source