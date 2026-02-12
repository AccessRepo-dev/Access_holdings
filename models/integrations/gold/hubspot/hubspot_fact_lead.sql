{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        database=get_target_database(company),
        alias="fact_lead",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

with
    deal_contacts as (
        select distinct contact_id, max(deal_id) as deal_id
        from {{ ref('hubspot_deal_contact_current') }} 
        where is_active = 1
        group by 1
    )

    {% if company == "wagway" %}
        ,
        deal_contacts_pawville as (
            select distinct contact_id, max(deal_id) as deal_id
            from {{ get_silver_source(company, "HUBSPOT_DEAL_CONTACT") }}
            where is_active = 1
            group by 1
        )
    {% endif %}

select
    id_date_key,
    id as lead_id,
    property_createdate as lead_date,
    property_hubspot_owner_id as owner_id,
    concat(property_firstname, ' ', property_lastname) as company,
    property_lifecyclestage as status,
    {% if company == "playfly" %}
        case
            when
                property_lifecyclestage in (
                    'subscriber',
                    'salesqualifiedlead',
                    'customer',
                    'opportunity',
                    'marketingqualifiedlead'
                )
            then 'Qualified Lead'
            when property_lifecyclestage in ('evangelist', 'other', 'lead')
            then 'Lead'
        end as mapped_leadstage,
    {% else %} cast(null as varchar) as mapped_leadstage,
    {% endif %}
    is_active,
    dc.deal_id as converted_opportunity_key,
    {% if company == "wagway" %} 'HUBSPOT_PUPS' as source_schema,

    {% else %} concat('HUBSPOT_', '{{company | upper}}') as source_schema,

    {% endif %}
    current_timestamp()::timestamp_ntz as gold_load_date
from {{ ref('hubspot_contact_current') }} c
left join deal_contacts dc on dc.contact_id = c.id

{% if company == "wagway" %}
    union all

    select
        id_date_key,
        id as lead_id,
        property_createdate as lead_date,
        property_hubspot_owner_id as owner_id,
        concat(property_firstname, ' ', property_lastname) as company,
        property_lifecyclestage as status,
        cast(null as varchar) as mapped_leadstage,
        is_active,
        dc.deal_id as converted_opportunity_key,
        'HUBSPOT_PAWVILLE' as source_schema,
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_CONTACT") }} c
    left join deal_contacts_pawville dc on dc.contact_id = c.id

{% endif %}