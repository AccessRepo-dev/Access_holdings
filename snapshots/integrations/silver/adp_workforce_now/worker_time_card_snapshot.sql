{% snapshot adp_workforce_now_company_snapshot %}

{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'adp_workforce_now') %}
 
      

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower) in ["adp_workforce_now"] and (var("company", "zeus") | lower) in ["zeus"],
        database = get_raw_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_WORKER_TIME_CARD', 
        unique_key='id',
        strategy='timestamp',
        updated_at='_Fivetran_sync',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'WORKER_TIME_CARD') }}

{% endsnapshot %}
