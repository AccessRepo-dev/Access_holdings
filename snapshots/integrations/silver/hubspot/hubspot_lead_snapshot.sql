{% snapshot hubspot_lead_snapshot %}

{% set company = var('company', 'wagway') %}
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
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot"]
        and (var("company", "wagway") | lower) in ["wagway", "playfly"],
        database = get_raw_database(company),
        target_schema= snapshot_schema,
        alias= sourcesystem ~ '_LEAD', 
        unique_key='ID',
        strategy='timestamp',
        updated_at='_FIVETRAN_SYNCED',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'LEAD') }}

{% endsnapshot %}
