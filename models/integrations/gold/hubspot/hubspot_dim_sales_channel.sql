{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"] and var("company", "none") in ["wagway", "playfly"]) }}


{{
    config(
        database=get_target_database(company),
        alias="dim_sales_channel",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["ID", "SOURCE_SCHEMA"],
    )
}}



select
    distinct
        md5(   
        coalesce(nullif(A.property_hs_analytics_source,''), '') || '|' ||
        coalesce('HUBSPOT','')
        ) as ID,
        CASE 
            WHEN A.property_hs_analytics_source is null or A.property_hs_analytics_source = '' then 'UNKNOWN' 
                else A.property_hs_analytics_source
        end as SALES_CHANNEL,

        {% if company == "wagway" %}
            'HUBSPOT_PUPS' as SOURCE_SCHEMA,

        {%else%}

            CONCAT('HUBSPOT_','{{company | upper}}') as SOURCE_SCHEMA,

        {% endif %}

        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_DEAL") }} A



{% if company == 'wagway'%} 

UNION ALL

select
    distinct
         md5(   
        coalesce(nullif(A.property_hs_analytics_source,''), '') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as ID,
        CASE 
            WHEN A.property_hs_analytics_source is null or A.property_hs_analytics_source = '' then 'UNKNOWN' 
                else A.property_hs_analytics_source
        end as SALES_CHANNEL,
        'HUBSPOT_PAWVILLE' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} A

{% endif %}