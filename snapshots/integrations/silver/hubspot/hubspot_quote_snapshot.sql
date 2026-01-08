{% snapshot hubspot_quote_snapshot %}

{% set company = var('company', 'amh') %}
{% set sourcesystem = var('sourcesystem', 'hubspot') %}
 
      

{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot"]
        and (var("company", "amh") | lower) in ["amh"],
        database = get_raw_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_QUOTE', 
        unique_key='ID',
        strategy='timestamp',
        updated_at='PROPERTY_HS_LASTMODIFIEDDATE',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'QUOTE') }}

{% endsnapshot %}
