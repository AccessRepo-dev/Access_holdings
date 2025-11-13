{% snapshot hubspot_pups_products %}

{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
 
      

{{
    config(
        enabled = (var('company') | lower == 'wagway') and var('sourcesystem') | lower == 'hubspot',
        database = get_target_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_PUPS_PRODUCTS', 
        unique_key='id',
        strategy='timestamp',
        updated_at='PROPERTY_HS_LASTMODIFIEDDATE',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'PUPS_PRODUCTS') }}

{% endsnapshot %}
