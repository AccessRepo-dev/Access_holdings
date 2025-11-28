{% snapshot hubspot_users %}


{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') | lower in ['hubspot', 'hubspot_pawville']) }}

{{
    config(
        database = get_raw_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias = sourcesystem ~ '_USERS',
        unique_key='ID',
        strategy='timestamp',
        updated_at='_FIVETRAN_SYNCED',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'USERS') }}

{% endsnapshot %}
