{% snapshot hubspot_owner_team_snapshot %}

{% set company = var('company', 'wagway') %}
{% set sourcesystem = var('sourcesystem', 'hubspot') %}
 
      

{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot"]
        and (var("company", "wagway") | lower) in ["wagway"],
        database = get_raw_database(company),
        target_schema= target_snapshot_schema(sourcesystem),
        alias= sourcesystem ~ '_OWNER_TEAM', 
        unique_key=['OWNER_ID','TEAM_ID'] ,
        strategy='timestamp',
        updated_at='_FIVETRAN_SYNCED',
        invalidate_hard_deletes=True
    )
}}

select
    *
from {{ get_raw_source(company, sourcesystem, 'OWNER_TEAM') }}

{% endsnapshot %}
