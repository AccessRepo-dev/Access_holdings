{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"] and var("company", "none") in ["wagway", "playfly"]) }}



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
        distinct
        A.deal_id as OPPORTUNITY_ID,
        A.property_dealname as OPPORTUNITY_NAME,
        A.property_createdate as OPPORTUNITY_DATE,
        md5(   
        coalesce(nullif(A.property_hs_analytics_source,''), '') || '|' ||
        coalesce('HUBSPOT','')
        ) as SALES_CHANNEL_ID,
        

        {% if company == 'playfly'%} 
            md5(   
                coalesce(A.property_product_group,'') || '|' ||
                coalesce('HUBSPOT','')
                ) as PRODUCT_CATEGORY_ID,
        {% else %}
        
            md5(   
                coalesce(A.property_service_category,'') || '|' ||
                coalesce('HUBSPOT','')
                ) as PRODUCT_CATEGORY_ID,

        {% endif %}
        
        md5(
        coalesce(nullif(C.property_city,''), '') || '|' ||
        coalesce(nullif(C.property_state,''), '') || '|' ||
        coalesce(nullif(C.property_country,''), '') || '|' ||
        coalesce('HUBSPOT','')
        ) as LOCATION_ID,
        A.property_closedate as CLOSE_DATE,
        cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = TRUE THEN 1
    ELSE 0 END as Boolean) as IS_WON,
        cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END as Boolean) AS IS_CLOSED,

        null as PROPOSAL_REQUESTED_DATE,
        null as PROPOSAL_SENT_DATE,
        null as NEGOTIATION_DATE,
        null as CLOSED_WON_DATE,
        null as CLOSED_LOST_DATE,   

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

{% if company == 'wagway'%} 

UNION ALL

select
        distinct
        A.deal_id as OPPORTUNITY_ID,
        A.property_dealname as OPPORTUNITY_NAME,
        A.property_createdate as OPPORTUNITY_DATE,
        md5(   
        coalesce(nullif(A.property_hs_analytics_source,''), '') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as SALES_CHANNEL_ID,
         md5(   
        coalesce(A.property_service_category,'') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as PRODUCT_CATEGORY_ID,
        md5(
        coalesce(nullif(C.property_city,''), '') || '|' ||
        coalesce(nullif(C.property_state,''), '') || '|' ||
        coalesce(nullif(C.property_country,''), '') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as LOCATION_ID,
        A.property_closedate as CLOSE_DATE,
        cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = TRUE THEN 1
    ELSE 0 END as Boolean) as IS_WON,
        cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END as Boolean) AS IS_CLOSED,

        null as PROPOSAL_REQUESTED_DATE,
        null as PROPOSAL_SENT_DATE,
        null as NEGOTIATION_DATE,
        null as CLOSED_WON_DATE,
        null as CLOSED_LOST_DATE, 

        A.property_hs_lastmodifieddate as LAST_MODIFIED_DATE,
        'HUBSPOT_PAWVILLE' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} A
    LEFT JOIN deal_contacts_pawville B ON A.DEAL_ID = B.DEAL_ID
    LEFT JOIN {{ get_silver_source(company, "HUBSPOT_PAWVILLE_CONTACT") }} C ON c.id = B.contact_id and c.is_active = 1
where a.is_active = 1

{% endif %}