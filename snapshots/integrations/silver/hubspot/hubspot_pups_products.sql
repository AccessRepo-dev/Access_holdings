{% snapshot hubspot_products %}


{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot']) }}

{% if company == 'wagway' and sourcesystem == 'hubspot' %}


{% endif %}

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
{{ get_raw_source(company, sourcesystem, 'PUPS_PRODUCTS') }}

{% endsnapshot %}
