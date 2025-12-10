{% set company = var("company","wagway") %}
{{ config(enabled=var("sourcesystem", "hubspot") in ["hubspot", "hubspot_pawville"]) }}
{{ config(enabled=var("company", "wagway") in ["wagway"]) }}
{{
    config(
        database=get_target_database(company),
        alias="dim_sales_channel",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID",
    )
}}



select
    distinct
        md5(   
        coalesce(A.property_hs_analytics_source,'') || '|' ||
        coalesce('HUBSPOT','')
        ) as ID,
        CASE 
            WHEN A.property_hs_analytics_source is null then 'UNKNOWN' 
                else A.property_hs_analytics_source
        end as SALES_CHANNEL,
        'HUBSPOT' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_DEAL") }} A

UNION ALL

{% if company == 'wagway'%} 

select
    distinct
        md5(   
        coalesce(A.property_hs_analytics_source,'') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as ID,
        CASE 
            WHEN A.property_hs_analytics_source is null then 'UNKNOWN' 
                else A.property_hs_analytics_source
        end as SALES_CHANNEL,
        'HUBSPOT_PAWVILLE' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} A

{% endif %}