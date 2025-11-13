{% snapshot hubspot_deal_pipeline_stage %}

{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') | lower in ['hubspot', 'hubspot_pawville']) }}
 
      

{{
    config(
        database = get_target_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_DEAL_PIPELINE_STAGE', 
        unique_key='STAGE_ID',
        strategy='timestamp',
        updated_at='UPDATED_AT',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'DEAL_PIPELINE_STAGE') }}

{% endsnapshot %}
