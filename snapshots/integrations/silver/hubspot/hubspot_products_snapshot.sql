{% snapshot hubspot_products %}

{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
 
      

{{
    config(
        enabled =  var('sourcesystem') | lower == 'hubspot',
        database = get_raw_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_PRODUCT', 
        unique_key='id',
        strategy='timestamp',
        updated_at='PROPERTY_HS_LASTMODIFIEDDATE',
        invalidate_hard_deletes=True
    )
}}

select
    *
{%if company == 'wagway'%}
from {{ get_raw_source(company, sourcesystem, 'PUPS_PRODUCTS') }}
{%else%}
from {{ get_raw_source(company, sourcesystem, 'PRODUCT') }}
{%endif%}
{% endsnapshot %}
