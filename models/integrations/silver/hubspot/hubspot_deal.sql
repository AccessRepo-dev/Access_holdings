{% set company = var("company") | upper %}
{% set sourcesystem = var("sourcesystem") | upper %}

{{
    config(
        enabled=var("sourcesystem") | lower in ["hubspot", "hubspot_pawville"],
        materialized="incremental",
        database=get_target_database(company),
        alias=sourcesystem ~ "_DEAL",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}


with
    source as (
        select *
        from {{ source_snapshot_schema(company, sourcesystem ~ "_DEAL") }}
        {% if is_incremental() %}
            where
                (property_hs_lastmodifieddate > (select dateadd(day, -3, coalesce(max(property_hs_lastmodifieddate), '1900-01-01')) from {{ this }}) 
            OR 
                (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
        {% else %} where 1 = 1
        {% endif %}
    ),

    cleaned as (

        select
            concat(
                deal_id, '_', to_varchar(dbt_valid_from, 'YYYYMMDDHH24MISSFF3')
            ) as id_date_key,
            cast(deal_id as number) as deal_id,
            trim(property_dealname) as property_dealname,

            {% if company | lower != "playfly" %}
                cast(property_location_id as int) as property_location_id,
            {% else %} cast(null as int) as property_location_id,
            {% endif %}

            {% if company | lower == "playfly" %}
                trim(property_product_group) as property_product_group,
            {% endif %}

            property_amount,
            trim(deal_pipeline_id) as deal_pipeline_id,
            trim(deal_pipeline_stage_id) as deal_pipeline_stage_id,
            cast(trim(property_closedate) as timestamp_ntz) as property_closedate,
            cast(trim(property_createdate) as timestamp_ntz) as property_createdate,
            cast(
                trim(property_hs_createdate) as timestamp_ntz
            ) as property_hs_createdate,
            cast(
                trim(property_hs_lastmodifieddate) as timestamp_ntz
            ) as property_hs_lastmodifieddate,
            cast(trim(owner_id) as number) as owner_id,
            trim(property_hs_all_owner_ids) as property_hs_all_owner_ids,
            trim(property_dealtype) as property_dealtype,
            cast(
                trim(property_hs_forecast_amount) as float
            ) as property_hs_forecast_amount,
            cast(
                trim(property_hs_deal_stage_probability) as float
            ) as property_hs_deal_stage_probability,

            {% if company | lower != "amh" %}
                trim(property_description) as property_description,
            {% endif %}
            {% if company | lower == "amh" %}
                trim(property_service_request) as property_service_request,
            {% endif %}
            PROPERTY_HS_IS_CLOSED_WON,
            PROPERTY_HS_IS_CLOSED_LOST,
            {% if sourcesystem == "HUBSPOT_PAWVILLE" %}
                null as property_club_c, 
                null as property_service_type,
                null as property_service_category,
            {% elif company | lower == "wagway" and sourcesystem == "HUBSPOT" %}
                trim(property_club_c) as property_club_c,
                trim(property_service_type) as property_service_type,
                trim(property_service_category) as property_service_category,
            {% endif %}

            trim(property_hs_analytics_source) as property_hs_analytics_source,
            cast(
                trim(property_hs_projected_amount) as float
            ) as property_hs_projected_amount,

            {% if company | lower not in ["amh", "playfly"] %}
                cast(property_invoice_id as number) as property_invoice_id,
            {% else %} cast(null as number) as property_invoice_id,
            {% endif %}

            current_timestamp()::timestamp_ntz as silver_load_date,
            cast(dbt_valid_from as timestamp_ntz) as dbt_valid_from,
            cast(dbt_valid_to as timestamp_ntz) as dbt_valid_to,
            _FIVETRAN_SYNCED,
            case when dbt_valid_to is null then 1 else 0 end as is_active

        from source
    )

select *
from cleaned
