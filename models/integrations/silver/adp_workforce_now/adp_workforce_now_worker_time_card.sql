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
        from {{ get_raw_source(company, sourcesystem, "WORKER_TIME_CARD") }}
        {% if is_incremental() %}
            where
                _fivetran_synced > (
                    select
                        dateadd(day, -3, coalesce(max(_fivetran_synced), '1900-01-01'))
                    from {{ this }}
                )
        {% else %} where 1 = 1
        {% endif %}

    ),

    cleaned as (
        select
            trim(id) as id,
            trim(worker_id) as worker_id,
            trim(associate_oid) as associate_oid,
            trim(person_legal_name_given_name) as person_legal_name_given_name,
            trim(person_legal_name_family_name_1) as person_legal_name_family_name_1,
            trim(person_legal_name_formatted_name) as person_legal_name_formatted_name,

            exceptions_indicator as exceptions_indicator,

            cast(time_period_start_date as date) as time_period_start_date,
            cast(time_period_end_date as date) as time_period_end_date,

            trim(time_period_period_status) as time_period_period_status,
            trim(position_id) as position_id,
            trim(total_period_time_duration) as total_period_time_duration,

            cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,

            trim(review_status_code) as review_status_code,
            trim(processing_status_code) as processing_status_code,
            trim(period_code) as period_code,
            current_timestamp() as silver_load_date
        from source_data

    )

select *
from cleaned
