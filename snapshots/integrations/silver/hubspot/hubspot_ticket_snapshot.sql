{% snapshot hubspot_ticket %}


{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{
    config(
        enabled = (var('company') | lower in ['wagway','playfly']) and var('sourcesystem') | lower == 'hubspot',
        database = get_raw_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_TICKET', 
        unique_key='ID',
        strategy='timestamp',
        updated_at='PROPERTY_HS_LASTMODIFIEDDATE',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'TICKET') }}

{% endsnapshot %}
