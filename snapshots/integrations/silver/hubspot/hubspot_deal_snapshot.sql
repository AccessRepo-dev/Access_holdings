{% snapshot hubspot_deal %}


{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') | lower in ['hubspot', 'hubspot_pawville']) }}

{{
    config(
        database = get_target_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_DEAL', 
        unique_key='DEAL_ID',
        strategy='timestamp',
        updated_at='PROPERTY_HS_LASTMODIFIEDDATE',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'DEAL') }}

{% endsnapshot %}
