{% snapshot hubspot_deal_stage_snapshot %}


{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') | lower in ['hubspot', 'hubspot_pawville']) }}
{{ config(enabled = var('company', 'wagway') | lower in ["wagway", "playfly", "amh"]) }}

{{
    config(
        database = get_raw_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_DEAL_STAGE', 
        unique_key=['DEAL_ID','VALUE','DATE_ENTERED'],
        strategy='timestamp',
        updated_at='_FIVETRAN_SYNCED',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'DEAL_STAGE') }}

{% endsnapshot %}
