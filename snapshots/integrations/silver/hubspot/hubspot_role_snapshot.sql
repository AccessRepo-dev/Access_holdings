{% snapshot hubspot_role %}


{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{
    config(
        enabled = (var('company') | lower in ['wagway','playfly','amh']) and (var('sourcesystem') | lower in ['hubspot','hubspot_pawville']),
        database = get_target_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_ROLE', 
        unique_key='ID',
        strategy='timestamp',
        updated_at='_FIVETRAN_SYNCED',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'ROLE') }}

{% endsnapshot %}
