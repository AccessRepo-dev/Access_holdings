{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        schema="silver",
        unique_key="ID_DATE_KEY",
        materialized="incremental",
        incremental_strategy="merge",
        on_schema_change="sync_all_columns",
    )
}}


with
    raw as (
        select *
        from {{ ref("salesforce_campaign_snapshot") }}
        {% if is_incremental() %}
            where
                (
                    cast(last_modified_date as timestamp_ntz) > (
                        select
                            dateadd(
                                day,
                                -3,
                                coalesce(
                                    max(last_modified_date), '1900-01-01'::timestamp_ntz
                                )
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
        select distinct
            concat(
                id, '_', to_varchar(dbt_valid_from, 'YYYYMMDDHH24MISSFF3')
            ) as id_date_key,
            trim(id) as campaign_id,
            trim(name) as name,
            trim(type) as type,
            trim(status) as status,
            cast(start_date as timestamp_ntz) as start_date,
            cast(end_date as timestamp_ntz) as end_date,
            cast(expected_revenue as number) as expected_revenue,
            cast(budgeted_cost as number) as budgeted_cost,
            cast(actual_cost as number) as actual_cost,
            number_sent,
            trim(owner_id) as owner_id,
            trim(description) as description,
            cast(created_date as timestamp_ntz) as created_date,
            cast(last_modified_date as timestamp_ntz) as last_modified_date,
            _fivetran_deleted as _fivetran_deleted,
            current_timestamp()::timestamp_ntz as silver_load_date,
            cast(dbt_valid_from as timestamp_ntz) as dbt_valid_from,
            cast(dbt_valid_to as timestamp_ntz) as dbt_valid_to,
            case when dbt_valid_to is null then 1 else 0 end as is_active
        from raw
    )

select *
from cleaned
