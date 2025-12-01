{% snapshot hubspot_contact %}

{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') | lower in ['hubspot', 'hubspot_pawville']) }}
 
      

{{
    config(
        database = get_raw_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_CONTACT', 
        unique_key='id',
        strategy='timestamp',
        updated_at='PROPERTY_LASTMODIFIEDDATE',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'CONTACT') }}

{% endsnapshot %}
