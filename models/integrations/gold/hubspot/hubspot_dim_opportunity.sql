{% set company = var("company","wagway") %}
{{ config(enabled = var('sourcesystem', 'hubspot') in ["hubspot", "hubspot_pawville"] and var('company','wagway') == 'wagway') }}
{{
    config(
        database=get_target_database(company),
        alias="dim_opportunity",
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
        A.deal_id as OPPORTUNITY_ID,
        A.property_dealname as OPPORTUNITY_NAME,
        A.property_createdate as OPPORTUNITY_DATE,
        md5(   
        coalesce(A.property_hs_analytics_source,'') || '|' ||
        coalesce('HUBSPOT_PUPS','')
        ) as SALES_CHANNEL_ID,
         md5(   
        coalesce(A.property_service_category,'') || '|' ||
        coalesce('HUBSPOT_PUPS','')
        ) as PRODUCT_CATEGORY_ID,
        md5(
        coalesce(C.property_city,'') || '|' ||
        coalesce(C.property_state,'') || '|' ||
        coalesce(C.property_country,'') || '|' ||
        coalesce('HUBSPOT_PUPS','')
        ) as LOCATION_ID,
        A.property_closedate as CLOSE_DATE,
        CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = TRUE THEN 1
        ELSE 0 END as IS_WON,
        CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END AS IS_CLOSED,
        A.property_hs_lastmodifieddate as LAST_MODIFIED_DATE,


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

UNION ALL

{% if company == 'wagway'%} 

select
        A.deal_id as OPPORTUNITY_ID,
        A.property_dealname as OPPORTUNITY_NAME,
        A.property_createdate as OPPORTUNITY_DATE,
        md5(   
        coalesce(A.property_hs_analytics_source,'') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as SALES_CHANNEL_ID,
         md5(   
        coalesce(A.property_service_category,'') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as PRODUCT_CATEGORY_ID,
        md5(
        coalesce(C.property_city,'') || '|' ||
        coalesce(C.property_state,'') || '|' ||
        coalesce(C.property_country,'') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as LOCATION_ID,
        A.property_closedate as CLOSE_DATE,
        CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = TRUE THEN 1
        ELSE 0 END as IS_WON,
        CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END AS IS_CLOSED,
        A.property_hs_lastmodifieddate as LAST_MODIFIED_DATE,
        'HUBSPOT_PAWVILLE' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} A
    LEFT JOIN deal_contacts_pawville B ON A.DEAL_ID = B.DEAL_ID
    LEFT JOIN {{ get_silver_source(company, "HUBSPOT_PAWVILLE_CONTACT") }} C ON c.id = B.contact_id and c.is_active = 1
where a.is_active = 1

{% endif %}