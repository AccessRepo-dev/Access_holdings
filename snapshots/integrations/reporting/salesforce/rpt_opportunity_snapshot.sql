{% snapshot rpt_opportunity_snapshot %}

{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('company', 'none') | lower in ['zeus']) }}
{{ config(enabled = var('sourcesystem', 'none') | lower in ['salesforce']) }}
 
      

{{
    config(
        database = get_target_database(company),
        target_schema= 'GOLD',
        alias= 'rpt_opportunity_snapshot', 
        unique_key='id_date_key',
        strategy='timestamp',
        updated_at='GOLD_LOAD_DATE',
        invalidate_hard_deletes=True
    )
}}

select
    id_date_key,opportunity_id,account_id,user_id,owner_id,stage_name,amount,gold_load_date
from {{ get_gold_source(company, 'SALESFORCE_FACT_OPPORTUNITY') }}
where IS_ACTIVE = 1

{% endsnapshot %}
