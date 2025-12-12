{% snapshot salesforce_opportunity_line_item %}


{% set company = var('company','zeus') %}
{% set sourcesystem = var('sourcesystem','salesforce') %}
{{ config(enabled = var('sourcesystem', 'salesforce') == 'salesforce') }}
{{ config(enabled = var('company','zeus') == 'zeus') }}

{{
    config(
        database = get_raw_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        unique_key='id',
        strategy='timestamp',
        updated_at='LAST_MODIFIED_DATE',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'OPPORTUNITY_LINE_ITEM') }}

{% endsnapshot %}
