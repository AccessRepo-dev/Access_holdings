{% snapshot hubspot_deal_contact_snapshot %}

{% set company = var('company', 'amh') %}
{% set sourcesystem = var('sourcesystem', 'hubspot') %}
 
      

{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot", "hubspot_pawville"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        database = get_raw_database(company),
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
