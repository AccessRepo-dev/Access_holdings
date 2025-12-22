{% snapshot hubspot_deal_stage_snapshot %}


{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
        enabled = (
            sourcesystem in ['hubspot', 'hubspot_pawville']
            and company in ['wagway', 'playfly', 'amh']
        ),
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
