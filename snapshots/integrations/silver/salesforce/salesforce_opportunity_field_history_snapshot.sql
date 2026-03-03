{% snapshot salesforce_opportunity_field_history_snapshot %}

{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
{% set is_ci = var('is_ci_run', false) %}

{# Determine schema based on CI/CD mode #}
{% if is_ci %}
    {% set snapshot_schema = target.schema %}
    {{ log("CI MODE - Using schema: " ~ snapshot_schema, info=True) }}
{% else %}
    {% set snapshot_schema = target_snapshot_schema(sourcesystem) %}
    {{ log("CD MODE - Using schema: " ~ snapshot_schema, info=True) }}
{% endif %}
      

{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database = get_raw_database(company),
        alias= sourcesystem ~ '_OPPORTUNITY_FIELD_HISTORY', 
        target_schema= snapshot_schema,
        unique_key='id',
        strategy='timestamp',
        updated_at='_FIVETRAN_SYNCED',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'OPPORTUNITY_FIELD_HISTORY') }}

{% endsnapshot %}
