{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'salesforce',
    database = get_target_database(company),
    schema = 'silver',
    unique_key = 'id',
    materialized = 'incremental',
    incremental_strategy = 'merge'
) }}

select 
    *
from {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY_LINE_ITEM') }}
{% if is_incremental() %}
    where 
        LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
            from {{ this }})
        and DBT_VALID_TO is null
{% else %}
    where DBT_VALID_TO is null
{% endif %}
