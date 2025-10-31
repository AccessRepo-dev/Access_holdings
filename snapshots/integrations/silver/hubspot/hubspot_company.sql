{% snapshot hubspot_company %}


{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') == 'hubspot') }}

{{
    config(
        database = get_target_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        unique_key='id',
        strategy='timestamp',
        updated_at='PROPERTY_HS_LASTMODIFIEDDATE',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'COMPANY') }}

{% endsnapshot %}
