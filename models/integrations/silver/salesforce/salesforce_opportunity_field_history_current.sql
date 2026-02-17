{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce", "salesforce_access_holdings"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        alias = sourcesystem ~ '_OPPORTUNITY_FIELD_HISTORY',
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
        from {{ ref("salesforce_opportunity_field_history_snapshot") }}
    {% if is_incremental()%}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}
    ),

    cleaned as (
        select
            concat(
                id, '_', to_varchar(dbt_valid_from, 'YYYYMMDDHH24MISSFF3')
            ) as id_date_key,
            trim(id) as id,
            trim(opportunity_id) as opportunity_id,
            is_deleted,
            trim(created_by_id) as created_by_id,
            cast(created_date as timestamp_ntz) as created_date,
            trim(field) as field,
            trim(data_type) as data_type,
            trim(old_value) as old_value,
            trim(new_value) as new_value,
            current_timestamp()::timestamp_ntz as silver_load_date,
            cast(dbt_valid_from as timestamp_ntz) as dbt_valid_from,
            cast(dbt_valid_to as timestamp_ntz) as dbt_valid_to,
            _FIVETRAN_SYNCED::timestamp_ntz  AS _FIVETRAN_SYNCED,
            case when dbt_valid_to is null then 1 else 0 end as is_active
        from raw
    )

select *
from cleaned
