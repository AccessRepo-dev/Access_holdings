{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("company", "wagway") | lower) in ["wagway"],
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID",
    )
}}

with
    source_data as (
        select *
        from {{ get_raw_source(company, sourcesystem, "ATTENDANCE") }}
        {% if is_incremental() %}
            where
                cast(_loaded_at as timestamp_ntz) > (
                    select
                        dateadd(
                            day,
                            -1,
                            coalesce(max(_loaded_at), '1900-01-01'::timestamp_ntz)
                        )
                    from {{ this }}
                )
        {% endif %}
    ),

    cleaned as (
        select
            /* Employee object parsing */
            employee:account_id::int as employee_account_id,
            trim(employee:display_name::text) as employee_display_name,

            /* Cleaning scalar columns */
            trim(status) as status,
            cast(last_end as timestamp_ntz) as last_end,
            trim(last_punch_action_type) as last_punch_action_type,
            cast(last_start as timestamp_ntz) as last_start,
            cast(_loaded_at as timestamp_tz) as _loaded_at,
            trim(_etl_batch_id) as _etl_batch_id,

            /* Cost center parsing */
            cc.value:index::int as cost_center_index,
            trim(cc.value:value.display_name::text) as cost_center_display_name,
            cc.value:value.id::int as cost_center_id,
            current_timestamp() as silver_load_date,

        from source_data
        left join lateral flatten(input => cost_centers) cc
    )

select *
from cleaned
