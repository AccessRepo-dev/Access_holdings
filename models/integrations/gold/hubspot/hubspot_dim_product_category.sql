{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"] and var("company", "none") in ["wagway", "playfly"]) }}


{{
    config(
        database=get_target_database(company),
        alias="dim_product_category",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["ID", "SOURCE_SCHEMA"],
    )
}}

select
        distinct
               

        {% if company == 'playfly'%} 
            md5(   
                coalesce(A.property_product_group,'') || '|' ||
                coalesce('HUBSPOT','')
                ) as ID,
        {% else %}
        
            md5(   
                coalesce(A.property_service_category,'') || '|' ||
                coalesce('HUBSPOT','')
                ) as ID,

        {% endif %}
        A.property_service_category as PRODUCT_CATEGORY,

         {% if company == "wagway" %}
            'HUBSPOT_PUPS' as SOURCE_SCHEMA,

        {%else%}

            CONCAT('HUBSPOT_','{{company | upper}}') as SOURCE_SCHEMA,

        {% endif %}

        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_DEAL") }} A
where a.is_active = 1

{% if company == 'wagway'%} 


UNION ALL

select
        distinct
        md5(   
        coalesce(A.property_service_category,'') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as ID,
        A.property_service_category as PRODUCT_CATEGORY,
        'HUBSPOT_PAWVILLE' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} A
where a.is_active = 1

{% endif %}