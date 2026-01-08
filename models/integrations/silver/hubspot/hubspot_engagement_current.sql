{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "hubspot") | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower)
        in ["hubspot", "hubspot_pawville"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        materialized="incremental",
        database=get_target_database(company),
        alias=sourcesystem ~ "_ENGAGEMENT",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

with
    source as (
        select *
        from {{ ref("hubspot_engagement_snapshot") }}

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
            cast(id as int) as id,
            cast(type as varchar) as type,
            _fivetran_synced,
            current_timestamp()::timestamp_ntz as silver_load_date,
            cast(dbt_valid_from as timestamp_ntz) as dbt_valid_from,
            cast(dbt_valid_to as timestamp_ntz) as dbt_valid_to,
            case when dbt_valid_to is null then 1 else 0 end as is_active
        from source
    )

select *
from cleaned
