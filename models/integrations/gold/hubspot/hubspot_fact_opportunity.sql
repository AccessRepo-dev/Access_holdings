{% set company = var("company") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"]) }}
{{ config(enabled=var("company", "none") in ["wagway", "playfly", "amh"]) }}
{{
    config(
        database=get_target_database(company),
        alias="fact_opportunity",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

select
    a.id_date_key,
    a.deal_id as opportunity_id,
    c.company_id as account_id,
    owner_id as user_id,  -- need to check if this needs to be owner or user
    b.label as stage_name,
    a.property_amount as amount,
    a.is_active,
    'HUBSPOT' as source_schema,
    current_timestamp()::timestamp_ntz as gold_load_date
from {{ get_silver_source(company, "HUBSPOT_DEAL") }} a
join
    {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE_STAGE") }} b
    on b.stage_id = a.deal_pipeline_stage_id
    and b.is_active = 1
join
    {{ get_silver_source(company, "HUBSPOT_DEAL_COMPANY") }} c
    on a.deal_id = c.deal_id
    and b.is_active = 1

{% if company == "wagway" %}
    union all

    select
        a.id_date_key,
        a.deal_id as opportunity_id,
        c.company_id as account_id,
        owner_id as user_id,  -- need to check if this needs to be owner or user
        b.label as stage_name,
        a.property_amount as amount,
        a.is_active,
        'HUBSPOT_PAWVILLE' as source_schema,
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a
    join
        {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_PIPELINE_STAGE") }} b
        on b.stage_id = a.deal_pipeline_stage_id
        and b.is_active = 1
    join
        {{ get_silver_source(company, "HUBSPOT_PAWVILLE_COMPANY") }} c
        on a.deal_id = c.deal_id
        and b.is_active = 1
{% endif %}
