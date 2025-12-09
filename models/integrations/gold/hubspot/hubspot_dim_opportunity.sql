{% set company = var("company") %}
{{ config(enabled=var("sourcesystem", "hubspot") in ["hubspot", "hubspot_pawville"]) }}
{{ config(enabled=var("company", "none") in ["wagway", "playfly", "amh"]) }}
{{
    config(
        database=get_target_database(company),
        alias="dim_opportunity",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

select
    deal_id as OPPORTUNITY_ID,
    property_dealname as OPPORTUNITY_NAME,
    property_createdate as OPPORTUNITY_DATE,
    property_hs_analytics_source as SALES_CHANNEL,
    property_service_category as PRODUCT_CATEGORY,
    property_location_id as LOCATION_ID, -- need to update
    property_hs_lastmodifieddate as LAST_MODIFIED_DATE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE, 
    'HUBSPOT' as SOURCE_SCHEMA,
    current_timestamp()::timestamp_ntz as gold_load_date
from {{ get_silver_source(company, "HUBSPOT_DEAL") }} a
where a.is_active = 1