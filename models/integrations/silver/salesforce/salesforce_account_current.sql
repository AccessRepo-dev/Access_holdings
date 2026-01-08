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

        from {{ ref("salesforce_account_snapshot") }}

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
        select
            concat(
                id, '_', to_varchar(dbt_valid_from, 'YYYYMMDDHH24MISSFF3')
            ) as id_date_key,
            id as account_id,
            trim(account_source) as account_source,
            external_account_id_c as external_account_id,
            trim(name) as name,
            trim(type) as type,
            trim(record_type_name_c) as record_type_name_c,
            parent_id as parent_id,
            trim(parent_company_zm_c) as parent_company,
            trim(industry) as industry,
            try_cast(number_of_employees as int) as number_of_employees,
            cast(revenue_c as number) as annual_revenue,
            trim(website) as website,
            trim(billing_street) as billing_street,
            trim(billing_city) as billing_city,
            trim(billing_state) as billing_state,
            try_cast(billing_postal_code as int) as billing_postal_code,
            trim(billing_country) as billing_country,
            trim(shipping_street) as shipping_street,
            trim(shipping_city) as shipping_city,
            trim(shipping_state) as shipping_state,
            try_cast(shipping_postal_code as int) as shipping_postal_code,
            trim(shipping_country) as shipping_country,
            trim(owner_id) as owner_id,
            created_date,
            created_by_id,
            cast(last_modified_date as timestamp_ntz) as last_modified_date,
            trim(last_modified_by_id) as last_modified_by_id,
            trim(description) as description,
            current_timestamp()::timestamp_ntz as silver_load_date,
            cast(dbt_valid_from as timestamp_ntz) as dbt_valid_from,
            cast(dbt_valid_to as timestamp_ntz) as dbt_valid_to,
            case when dbt_valid_to is null then 1 else 0 end as is_active
        from raw
    )

select *
from cleaned
