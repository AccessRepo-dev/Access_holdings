{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        database=get_target_database(company),
        alias="dim_product_category",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["ID", "SOURCE_SCHEMA"],
    )
}}

with
    pups as (
        select distinct

            {% if company | lower == "playfly" %}
                md5(
                    coalesce(a.property_product_group, '')
                    || '|'
                    || coalesce('HUBSPOT', '')
                ) as id,
                a.property_product_group as product_category,

            {% elif company | lower == "wagway" %}

                array_compact(
                    array_construct(
                        case
                            when property_dealname ilike '%Daycare%' then 'Daycare'
                        end,
                        case
                            when
                                property_dealname ilike '%Grooming%'
                                or property_dealname ilike '%Groom%'
                            then 'Grooming'
                        end,
                        case
                            when property_dealname ilike '%Training%' then 'Training'
                        end,
                        case
                            when
                                property_dealname ilike '%Pet Sitting%'
                                or property_dealname ilike '%Petsitting%'
                                or property_dealname ilike '%Pet-Sitting%'
                            then 'Pet Sitting'
                        end,
                        case
                            when
                                property_dealname ilike '%Overnights%'
                                or property_dealname ilike '%Overnight%'
                            then 'Overnights'
                        end,
                        case
                            when property_dealname ilike '%Boarding%' then 'Boarding'
                        end,
                        case
                            when property_dealname ilike '%Walking%' then 'Walking'
                        end,
                        case
                            when
                                property_dealname ilike '%Puppy Play Care%'
                                or property_dealname ilike '%Puppy Playcare%'
                            then 'Puppy Playcare'
                        end,
                        case
                            when property_dealname ilike '%Playcare%' then 'Playcare'
                        end,
                        case
                            when property_dealname ilike '%Gingr Sign Up%'
                            then 'Gingr Sign Up'
                        end,
                        case
                            when property_dealname ilike '%New Lead%' then 'New Lead'
                        end,
                        case
                            when property_dealname ilike '%Membership%'
                            then 'Membership'
                        end,
                        case
                            when
                                property_dealname ilike '%Wellness%'
                                or property_dealname ilike '%WellCare%'
                                or property_dealname ilike '%Well Care%'
                            then 'Wellness'
                        end,
                        case
                            when property_dealname ilike '%Transport%' then 'Transport'
                        end,
                        case
                            when
                                property_dealname ilike '%Veterinary%'
                                or property_dealname ilike '%Vet%'
                            then 'Veterinary'
                        end,
                        case when property_dealname ilike '%General%' then 'General' end
                    )
                ) as svc_array,
                case
                    when array_size(svc_array) = 0
                    then md5('' || '|HUBSPOT')
                    when
                        lower(svc_array[0]::string) in ('new lead', 'gingr sign up')
                        and array_size(svc_array) > 1
                    then md5(coalesce(svc_array[1]::string, '') || '|HUBSPOT')
                    else md5(coalesce(svc_array[0]::string, '') || '|HUBSPOT')
                end as id,

                case
                    when array_size(svc_array) = 0
                    then null
                    when
                        lower(svc_array[0]::string) in ('new lead', 'gingr sign up')
                        and array_size(svc_array) > 1
                    then svc_array[1]::string
                    else svc_array[0]::string
                end as product_category,

            {% else %}
                md5(
                    coalesce(a.property_service_request, '')
                    || '|'
                    || coalesce('HUBSPOT', '')
                ) as id,
                a.property_service_request as product_category,

            {% endif %}

            {% if company | lower == "wagway" %} 'HUBSPOT_PUPS' as source_schema,

            {% else %} concat('HUBSPOT_', '{{company | upper}}') as source_schema,

            {% endif %}

            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref('hubspot_deal_current') }} a
        where a.is_active = 1
    )

    {% if company | lower == "wagway" %}
        ,
        pawville as (

            select distinct
                array_compact(
                    array_construct(
                        case
                            when property_dealname ilike '%Daycare%' then 'Daycare'
                        end,
                        case
                            when
                                property_dealname ilike '%Grooming%'
                                or property_dealname ilike '%Groom%'
                            then 'Grooming'
                        end,
                        case
                            when property_dealname ilike '%Training%' then 'Training'
                        end,
                        case
                            when
                                property_dealname ilike '%Pet Sitting%'
                                or property_dealname ilike '%Petsitting%'
                                or property_dealname ilike '%Pet-Sitting%'
                            then 'Pet Sitting'
                        end,
                        case
                            when
                                property_dealname ilike '%Overnights%'
                                or property_dealname ilike '%Overnight%'
                            then 'Overnights'
                        end,
                        case
                            when property_dealname ilike '%Boarding%' then 'Boarding'
                        end,
                        case
                            when property_dealname ilike '%Walking%' then 'Walking'
                        end,
                        case
                            when
                                property_dealname ilike '%Puppy Play Care%'
                                or property_dealname ilike '%Puppy Playcare%'
                            then 'Puppy Playcare'
                        end,
                        case
                            when property_dealname ilike '%Playcare%' then 'Playcare'
                        end,
                        case
                            when property_dealname ilike '%Gingr Sign Up%'
                            then 'Gingr Sign Up'
                        end,
                        case
                            when property_dealname ilike '%New Lead%' then 'New Lead'
                        end,
                        case
                            when property_dealname ilike '%Membership%'
                            then 'Membership'
                        end,
                        case
                            when
                                property_dealname ilike '%Wellness%'
                                or property_dealname ilike '%WellCare%'
                                or property_dealname ilike '%Well Care%'
                            then 'Wellness'
                        end,
                        case
                            when property_dealname ilike '%Transport%' then 'Transport'
                        end,
                        case
                            when
                                property_dealname ilike '%Veterinary%'
                                or property_dealname ilike '%Vet%'
                            then 'Veterinary'
                        end,
                        case when property_dealname ilike '%General%' then 'General' end
                    )
                ) as svc_array,
                case
                    when array_size(svc_array) = 0
                    then md5('' || '|HUBSPOT_PAWVILLE')
                    when
                        lower(svc_array[0]::string) in ('new lead', 'gingr sign up')
                        and array_size(svc_array) > 1
                    then md5(coalesce(svc_array[1]::string, '') || '|HUBSPOT_PAWVILLE')
                    else md5(coalesce(svc_array[0]::string, '') || '|HUBSPOT_PAWVILLE')
                end as id,

                case
                    when array_size(svc_array) = 0
                    then null
                    when
                        lower(svc_array[0]::string) in ('new lead', 'gingr sign up')
                        and array_size(svc_array) > 1
                    then svc_array[1]::string
                    else svc_array[0]::string
                end as product_category,
                'HUBSPOT_PAWVILLE' as source_schema,
                current_timestamp()::timestamp_ntz as gold_load_date
            from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a
            where a.is_active = 1
        )

    {% endif %}

select distinct id, product_category, source_schema, gold_load_date
from pups

{% if company | lower == "wagway" %}
    union all
    select distinct id, product_category, source_schema, gold_load_date
    from pawville
{% endif %}
