{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"]) }}
{{ config(enabled=var("company", "none") in ["wagway"]) }}
{{
    config(
        database=get_target_database(company),
        alias="fact_lead",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

select
    ID_DATE_KEY,
    ID as LEAD_ID,
    PROPERTY_CREATEDATE as LEAD_DATE,
    PROPERTY_HUBSPOT_OWNER_ID as OWNER_ID,
    concat(property_firstname,' ',property_lastname) as COMPANY,
    PROPERTY_LIFECYCLESTAGE as STATUS,
    IS_ACTIVE,
    null as CONVERTED_OPPORTUNITY_ID,
    'HUBSPOT' as source_schema,
    current_timestamp()::timestamp_ntz as gold_load_date
from {{ get_silver_source(company, "HUBSPOT_CONTACT") }}

{% if company == "wagway" %}
    union all

select
    ID_DATE_KEY,
    ID as LEAD_ID,
    PROPERTY_CREATEDATE as LEAD_DATE,
    PROPERTY_HUBSPOT_OWNER_ID as OWNER_ID,
    concat(property_firstname,' ',property_lastname) as COMPANY,
    PROPERTY_LIFECYCLESTAGE as STATUS,
    IS_ACTIVE,
    null as CONVERTED_OPPORTUNITY_ID,
    'HUBSPOT_PAWVILLE' as source_schema,
    current_timestamp()::timestamp_ntz as gold_load_date
from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_CONTACT") }}

{% endif %}
