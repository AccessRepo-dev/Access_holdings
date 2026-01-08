{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_crm_location",
        incremental_strategy="merge",
        unique_key="ID",
    )
}}

with
    source as (
        select
            md5(
                coalesce(a.billing_city, '')
                || '|'
                || coalesce(a.billing_state, '')
                || '|'
                || coalesce(a.billing_country, '')
            ) as id,
            a.billing_city as city,
            a.billing_state as state,
            a.billing_country as country,
            concat('SALESFORCE_', '{{company | upper}}') as source_schema,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref('salesforce_opportunity_current') }} as b
        left join {{ ref('salesforce_account_current') }} as a
            on a.account_id = b.account_id
            and a.is_active = 1
        where b.is_active = 1

        {% if is_incremental() %}
            where
                last_modified_date > (
                    select coalesce(max(last_modified_date), '1900-01-01')
                    from {{ this }}
                )
        {% endif %}

        group by a.billing_city, a.billing_state, a.billing_country
    )

select *
from source
