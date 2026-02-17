{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        database=get_target_database(company),
        alias="dim_company",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["ID"],
    )
}}

select
    id,
    property_name as name,
    property_domain as domain,
    property_phone as phone,
    property_industry as industry,
    property_address as address,
    property_city as city,
    property_state as state,
    property_country as country,
    property_hubspot_owner_id as owner_id,
    property_createdate as create_date,
    property_hs_lastmodifieddate as last_modified_date,
    property_company_type as property_company_type,
    property_annualrevenue as annual_revenue,
    property_numberofemployees as number_of_employees,
    {% if company == "wagway" %} 'HUBSPOT_PUPS' as source_schema,

    {% else %} concat('HUBSPOT_', '{{company | upper}}') as source_schema,

    {% endif %}
    current_timestamp()::timestamp_ntz as gold_load_date
from {{ ref('hubspot_company_current') }}
where is_active = 1

{% if company == "wagway" %}

    union all

    select
        id,
        property_name as name,
        property_domain as domain,
        property_phone as phone,
        property_industry as industry,
        property_address as address,
        property_city as city,
        property_state as state,
        property_country as country,
        property_hubspot_owner_id as owner_id,
        property_createdate as create_date,
        property_hs_lastmodifieddate as last_modified_date,
        property_company_type as property_company_type,
        property_annualrevenue as annual_revenue,
        property_numberofemployees as number_of_employees,
        'HUBSPOT_PAWVILLE' as source_schema,
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_COMPANY") }}
    where is_active = 1

{% endif %}