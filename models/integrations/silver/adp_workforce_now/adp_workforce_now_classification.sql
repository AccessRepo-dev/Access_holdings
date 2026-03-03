{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower) in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID",
    )
}}

with
    source_data as (
        select *
        from {{ get_raw_source(company, sourcesystem, "CLASSIFICATION") }}
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
            trim(coalesce(classification_short_name, '')) as classification_short_name,
            trim(coalesce(classification_long_name, '')) as classification_long_name,
            trim(
                coalesce(classification_subdivision_type, '')
            ) as classification_subdivision_type,
            cast(
                classification_effective_date as date
            ) as classification_effective_date,
            trim(coalesce(type, '')) as type,
            trim(coalesce(classification, '')) as classification,
            trim(coalesce(name, '')) as name,
            cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,
            current_timestamp() as silver_load_date
        from source_data

    )

select *
from cleaned
