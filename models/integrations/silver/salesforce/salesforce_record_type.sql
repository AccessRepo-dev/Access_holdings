{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'salesforce',
    database = get_target_database(company),
    schema = 'silver',
    unique_key = 'id',
    strategy = 'timestamp',
    updated_at = 'LAST_MODIFIED_DATE',
    invalidate_hard_deletes = True
) }}

select
    *
from {{ get_silver_source(company, 'SALESFORCE_RECORD_TYPE') }}
where DBT_VALID_TO is null
