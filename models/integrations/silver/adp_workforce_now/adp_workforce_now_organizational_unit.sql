{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}
{{ config(enabled=var("sourcesystem", "adp_workforce_now") == "adp_workforce_now") }}

{{
    config(
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID",
    )
}}

with
    source_data as (
        select *
        from {{ get_raw_source(company, sourcesystem, "ORGANIZATIONAL_UNIT") }}
        {% if is_incremental() %}
            where
                    _fivetran_synced > (
                        select
                            dateadd(
                                day, -3, coalesce(max(_fivetran_synced), '1900-01-01')
                            )
                        from {{ this }}
                    )
        {% else %} where 1 = 1
        {% endif %}

    ),

    cleaned as (
        select
            trim(coalesce(id, '')) as id,
            trim(coalesce(name_short_name, '')) as name_short_name,
            trim(coalesce(name_long_name, '')) as name_long_name,
            trim(coalesce(name_subdivision_type, '')) as name_subdivision_type,
            cast(name_effective_date as date) as name_effective_date,
            trim(coalesce(type_short_name, '')) as type_short_name,
            trim(coalesce(type_long_name, '')) as type_long_name,
            trim(coalesce(type_subdivision_type, '')) as type_subdivision_type,
            cast(type_effective_date as date) as type_effective_date,
            trim(coalesce(type, '')) as type,
            trim(coalesce(name, '')) as name,
            cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,
            current_timestamp() as silver_load_date
        from source_data

    )

select *
from cleaned
