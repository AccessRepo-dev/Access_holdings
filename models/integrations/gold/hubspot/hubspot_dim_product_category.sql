{% set company = var("company","wagway") %}
{{ config(enabled=var("sourcesystem", "hubspot") in ["hubspot", "hubspot_pawville"]) }}
{{ config(enabled=var("company", "wagway") in ["wagway"]) }}
{{
    config(
        database=get_target_database(company),
        alias="dim_product_category",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID",
    )
}}

select
        md5(   
        coalesce(A.property_service_category,'') || '|' ||
        coalesce('HUBSPOT','')
        ) as ID,
        A.property_service_category as PRODUCT_CATEGORY,
        'HUBSPOT' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, "HUBSPOT_DEAL") }} A
where a.is_active = 1

UNION ALL

{% if company == 'wagway'%} 

select
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