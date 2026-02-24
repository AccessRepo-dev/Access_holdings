{% snapshot hubspot_owner_snapshot %}

{% set company = var('company', 'amh') %}
{% set sourcesystem = var('sourcesystem', 'hubspot') %}
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
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot", "hubspot_pawville"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        database = get_raw_database(company),
        target_schema= snapshot_schema,
        alias= sourcesystem ~ '_OWNER', 
        unique_key='OWNER_ID',
        strategy='timestamp',
        updated_at='UPDATED_AT',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'OWNER') }}

{% endsnapshot %}
