{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"]) }}
{{ config(enabled=var("company", "none") in ["wagway"]) }}
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
    null as account_id,
    property_hs_all_owner_ids as owner_id,
    b.label as stage_name,
    property_amount as amount,
    property_closedate as close_date,
    CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END AS IS_CLOSED,
    CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = TRUE THEN 1
        WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = FALSE THEN 0
    ELSE -1 END as IS_WON,
    property_hs_deal_stage_probability as probability,
    null as dbt_valid_from,
    null as dbt_valid_to,
    a.is_active,
    'HUBSPOT' as SOURCE_SCHEMA,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE,
from {{ get_silver_source(company, "HUBSPOT_DEAL") }} a
join
    {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE_STAGE") }} b
    on b.stage_id = a.deal_pipeline_stage_id
    and b.is_active = 1

{% if company == "wagway" %}
    union all

    select
        a.id_date_key,
        a.deal_id as opportunity_id,
        null as account_id,
        property_hs_all_owner_ids as owner_id,
        b.label as stage_name,
        property_amount as amount,
        property_closedate as close_date,
        CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END AS IS_CLOSED,
        CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = TRUE THEN 1
            WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = FALSE THEN 0
        ELSE -1 END as IS_WON,
        property_hs_deal_stage_probability as probability,
        null as dbt_valid_from,
        null as dbt_valid_to,
        a.is_active,
        'HUBSPOT_PAWVILLE' as source_schema,
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a
    join
        {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_PIPELINE_STAGE") }} b
        on b.stage_id = a.deal_pipeline_stage_id
        and b.is_active = 1
{% endif %}
