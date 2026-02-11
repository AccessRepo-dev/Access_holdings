{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        alias = sourcesystem ~ '_CAMPAIGN',
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
           {% if is_incremental()%}
        where 
            cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -1, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
        {% endif %}
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
            _FIVETRAN_SYNCED::timestamp_ntz  AS _FIVETRAN_SYNCED,
            current_timestamp()::timestamp_ntz as silver_load_date,
            cast(dbt_valid_from as timestamp_ntz) as dbt_valid_from,
            cast(dbt_valid_to as timestamp_ntz) as dbt_valid_to,
            case when dbt_valid_to is null then 1 else 0 end as is_active
        from raw
    )

select *
from cleaned
