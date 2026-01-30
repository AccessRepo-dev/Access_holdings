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
        from {{ get_raw_source(company, sourcesystem, "WORKER") }}
        {% if is_incremental() %}
            where
                _fivetran_synced > (
                    select
                        dateadd(day, -3, coalesce(max(_fivetran_synced), '1900-01-01'))
                    from {{ this }}
                )
        {% else %} where 1 = 1
        {% endif %} and _fivetran_deleted = false

    ),

    cleaned as (
        select
            trim(coalesce(id, '')) as id,
            trim(coalesce(associate_oid, '')) as associate_oid,
            cast(original_hire_date as date) as original_hire_date,
            cast(rehire_date as date) as rehire_date,
            cast(adjusted_service_date as date) as adjusted_service_date,
            cast(acquisition_date as date) as acquisition_date,
            cast(retirement_date as date) as retirement_date,
            cast(termination_date as date) as termination_date,
            cast(expected_termination_date as date) as expected_termination_date,
            trim(coalesce(status_short_name, '')) as status_short_name,
            trim(coalesce(status_long_name, '')) as status_long_name,
            trim(coalesce(status_subdivision_type, '')) as status_subdivision_type,
            cast(status_effective_date as date) as status_effective_date,
            trim(coalesce(status_reason_short_name, '')) as status_reason_short_name,
            trim(coalesce(status_reason_long_name, '')) as status_reason_long_name,
            trim(
                coalesce(status_reason_subdivision_type, '')
            ) as status_reason_subdivision_type,
            cast(status_reason_effective_date as date) as status_reason_effective_date,
            trim(coalesce(status_value, '')) as status_value,
            trim(coalesce(status_reason, '')) as status_reason,
            trim(coalesce(photo_url, '')) as photo_url,
            trim(coalesce(photo_media_type, '')) as photo_media_type,
            cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,
            coalesce(_fivetran_deleted, false) as _fivetran_deleted,
            current_timestamp() as silver_load_date
        from source_data

    )

select *
from cleaned
