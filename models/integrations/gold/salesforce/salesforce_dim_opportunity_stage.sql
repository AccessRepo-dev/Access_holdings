{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    enabled=false,
    database = get_target_database(company),
    materialized = 'table'
) }}

with source as (

    select
        DISTINCT    
        STAGE_NAME,
        MAX(PROBABILITY) AS PROBABILITY,
        MAX(IS_CLOSED) AS IS_CLOSED
    from {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }}
    group by STAGE_NAME

    {% if is_incremental() %}
        WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}
)
select *
from source