{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"] and var("company", "none") in ["wagway", "playfly","amh"]) }}



{{
    config(
        database=get_target_database(company),
        alias="fact_lead",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

with deal_contacts as (
        SELECT distinct contact_id , max(deal_id) as deal_id
        FROM {{ get_silver_source(company, "HUBSPOT_DEAL_CONTACT") }}
        where is_active = 1
        group by 1
        )

{% if company == 'wagway'%} 
        ,deal_contacts_pawville as (
        SELECT distinct contact_id , max(deal_id) as deal_id
        FROM {{ get_silver_source(company, "HUBSPOT_DEAL_CONTACT") }}
        where is_active = 1
        group by 1
        )
{% endif %}



select
    ID_DATE_KEY,
    ID as LEAD_ID,
    PROPERTY_CREATEDATE as LEAD_DATE,
    PROPERTY_HUBSPOT_OWNER_ID as OWNER_ID,
    concat(property_firstname,' ',property_lastname) as COMPANY,
    PROPERTY_LIFECYCLESTAGE as STATUS,
    IS_ACTIVE,
    dc.deal_id as CONVERTED_OPPORTUNITY_KEY,
    {% if company == "wagway" %}
        'HUBSPOT_PUPS' as SOURCE_SCHEMA,

    {%else%}

        CONCAT('HUBSPOT_','{{company | upper}}') as SOURCE_SCHEMA,

    {% endif %}
    current_timestamp()::timestamp_ntz as gold_load_date
from {{ get_silver_source(company, "HUBSPOT_CONTACT") }} c 
LEFT JOIN deal_contacts dc ON dc.contact_id = c.id

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
    dc.deal_id as CONVERTED_OPPORTUNITY_KEY,
    'HUBSPOT_PAWVILLE' as source_schema,
    current_timestamp()::timestamp_ntz as gold_load_date
from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_CONTACT") }} c 
LEFT JOIN deal_contacts_pawville dc ON dc.contact_id = c.id

{% endif %}