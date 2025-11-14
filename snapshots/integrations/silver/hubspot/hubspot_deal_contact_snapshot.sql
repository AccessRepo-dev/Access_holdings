{% snapshot hubspot_deal_contact %}


{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{
    config(
        enabled = var('sourcesystem') | lower in ['hubspot','hubspot_pawville'] and var('company') | lower in ['wagway', 'playfly','amh'],
        database = get_target_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_DEAL_CONTACT', 
        unique_key=['DEAL_ID','CONTACT_ID','TYPE_ID'],
        strategy='timestamp',
        updated_at='_FIVETRAN_SYNCED',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'DEAL_CONTACT') }}

{% endsnapshot %}
