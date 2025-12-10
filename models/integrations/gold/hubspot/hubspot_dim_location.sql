{% set company = var("company") %}
{{ config(enabled=var("sourcesystem", "hubspot") in ["hubspot", "hubspot_pawville"]) }}
{{ config(enabled=var("company", "wagway") in ["wagway", "playfly", "amh"]) }}
{{
    config(
        database=get_target_database(company),
        alias="dim_crm_location",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

with deal_contacts as (
        SELECT distinct deal_id, max(contact_id) as contact_id
        FROM {{ get_silver_source(company, "HUBSPOT_DEAL_CONTACT") }}
        where is_active = 1
        group by 1
        ),

        deal_contacts_pawville as (
        SELECT distinct deal_id, max(contact_id) as contact_id
        FROM {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_CONTACT") }}
        where is_active = 1
        group by 1
        )

select
    distinct
        md5(
        coalesce(C.property_city,'') || '|' ||
        coalesce(C.property_state,'') || '|' ||
        coalesce(C.property_country,'') || '|' ||
        coalesce('HUBSPOT','')
        ) as ID,
        C.property_city as CITY,
        C.property_state as STATE,
        C.property_country as COUNTRY,
        'HUBSPOT' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_DEAL") }} A
    LEFT JOIN deal_contacts B ON A.DEAL_ID = B.DEAL_ID
    LEFT JOIN {{ get_silver_source(company, "HUBSPOT_CONTACT") }} C ON c.id = B.contact_id and c.is_active = 1
where a.is_active = 1

UNION ALL

select
    distinct
        md5(
        coalesce(C.property_city,'') || '|' ||
        coalesce(C.property_state,'') || '|' ||
        coalesce(C.property_country,'') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as ID,
        C.property_city as CITY,
        C.property_state as STATE,
        C.property_country as COUNTRY,
        'HUBSPOT_PAWVILLE' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} A
    LEFT JOIN deal_contacts_pawville B ON A.DEAL_ID = B.DEAL_ID
    LEFT JOIN {{ get_silver_source(company, "HUBSPOT_PAWVILLE_CONTACT") }} C ON c.id = B.contact_id and c.is_active = 1
where a.is_active = 1