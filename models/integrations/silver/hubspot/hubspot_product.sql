{% set company = var("company") %}
{% set sourcesystem = var("sourcesystem") | upper %}

{{
    config(
        enabled=var("sourcesystem") | lower in ["hubspot"]
        and var("company") | lower in ["playfly", "amh"],
        materialized="incremental",
        database=get_target_database(company),
        alias=sourcesystem ~ "_PRODUCT",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

with
    source as (
        select *
        from {{ source_snapshot_schema(company, sourcesystem ~ "_PRODUCT") }}

        {% if is_incremental() %}
            where
                (
                    _fivetran_synced > (
                        select
                            dateadd(
                                day, -3, coalesce(max(_fivetran_synced), '1900-01-01')
                            )
                        from {{ this }}
                    )
                    or (
                        dbt_valid_to > (
                            select
                                dateadd(
                                    day, -3, coalesce(max(dbt_valid_to), '1900-01-01')
                                )
                            from {{ this }}
                        )
                    )
                )
        {% else %} where 1 = 1
        {% endif %}
    ),

    cleaned as (
        select
            concat(
                id, '_', to_varchar(dbt_valid_from, 'YYYYMMDDHH24MISSFF3')
            ) as id_date_key,
            cast(id as int) as product_id,

            /* ---------- Name ---------- */
            initcap(trim(property_name)) as product_name,

            {% if company in ["playfly", "wagway"] %}
                initcap(trim(property_description)) as property_description,
                initcap(trim(property_family)) as property_family,
            {% else %}
                cast(null as varchar) as property_description,
                cast(null as varchar) as property_family,
            {% endif %}

            /* ---------- Product Type ---------- */
            {% if company in ["amh", "playfly"] %}
                portal_id::number as portal_id,
                lower(trim(property_hs_pricing_model)) as pricing_model,
                lower(trim(property_hs_status)) as product_status,
            {% else %}
                cast(null as number) as portal_id,
                cast(null as varchar) as pricing_model,
                cast(null as varchar) as product_status,
            {% endif %}

            {% if company in ["amh"] %}
                lower(trim(property_hs_product_type)) as product_type,
                trim(property_hs_folder_id) as property_hs_folder_id,
            {% elif company == "playfly" %}
                lower(trim(property_product_category)) as product_type,
                cast(null as int) property_hs_folder_id,
            {% else %} cast(null as varchar) as product_type,
            {% endif %}

            cast(property_price as float) as price,

            /* ---------- Timestamps ---------- */
            {% if company == "wagway" %} property_hs_createdate as created_at,
            {% else %} property_createdate as created_at,
            {% endif %}
            property_hs_lastmodifieddate as updated_at,

            /* ---------- Fivetran Metadata ---------- */
            coalesce(_fivetran_deleted, false) as is_deleted,
            current_timestamp()::timestamp_ntz as silver_load_date,
            cast(dbt_valid_from as timestamp_ntz) as dbt_valid_from,
            cast(dbt_valid_to as timestamp_ntz) as dbt_valid_to,
            _fivetran_synced,
            case when dbt_valid_to is null then 1 else 0 end as is_active

        from source
    )

select *
from cleaned