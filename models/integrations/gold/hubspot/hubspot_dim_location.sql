{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"] and var("company", "none") in ["wagway", "playfly","amh"]) }}



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
        )

{% if company == 'wagway'%} 
        
        ,deal_contacts_pawville as (
        SELECT distinct deal_id, max(contact_id) as contact_id
        FROM {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_CONTACT") }}
        where is_active = 1
        group by 1
        )

{% endif %}

select
    distinct
        md5(
        coalesce(nullif(C.property_city,''), '') || '|' ||
        coalesce(nullif(C.property_state,''), '') || '|' ||
        coalesce(nullif(C.property_country,''), '') || '|' ||
        coalesce('HUBSPOT','')
        ) as ID,
        coalesce(nullif(C.property_city,''), '') as CITY,
        coalesce(nullif(C.property_state,''), '') as STATE,
        coalesce(nullif(C.property_country,''), '') as COUNTRY,

        {% if company == "wagway" %}
            'HUBSPOT_PUPS' as SOURCE_SCHEMA,

        {%else%}

            CONCAT('HUBSPOT_','{{company | upper}}') as SOURCE_SCHEMA,

        {% endif %}

        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_DEAL") }} A
    LEFT JOIN deal_contacts B ON A.DEAL_ID = B.DEAL_ID
    LEFT JOIN {{ get_silver_source(company, "HUBSPOT_CONTACT") }} C ON c.id = B.contact_id and c.is_active = 1
where a.is_active = 1

{% if company == 'wagway'%} 

UNION ALL

select
    distinct
        md5(
        coalesce(nullif(C.property_city,''), '') || '|' ||
        coalesce(nullif(C.property_state,''), '') || '|' ||
        coalesce(nullif(C.property_country,''), '') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as ID,
        coalesce(nullif(C.property_city,''), '') as CITY,
        coalesce(nullif(C.property_state,''), '') as STATE,
        coalesce(nullif(C.property_country,''), '') as COUNTRY,
        'HUBSPOT_PAWVILLE' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} A
    LEFT JOIN deal_contacts_pawville B ON A.DEAL_ID = B.DEAL_ID
    LEFT JOIN {{ get_silver_source(company, "HUBSPOT_PAWVILLE_CONTACT") }} C ON c.id = B.contact_id and c.is_active = 1
where a.is_active = 1

{% endif %}