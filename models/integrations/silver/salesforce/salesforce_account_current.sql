{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"] and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        alias = sourcesystem ~ '_ACCOUNT',
        schema="silver",
        unique_key="ID_DATE_KEY",
        materialized="incremental",
        incremental_strategy="merge",
        on_schema_change="sync_all_columns",
    )
}}


with
    raw as (
        select  concat(id,'_',to_varchar(dbt_valid_from,'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        {{ sf_canonical_account(company, sourcesystem) }},
        _FIVETRAN_DELETED,
        _fivetran_synced,
        current_timestamp() as silver_load_date,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then 1 else 0 end as is_active
        from {{ ref("salesforce_account_snapshot") }}

    {% if is_incremental()%}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -1, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}

    ),
    cleaned as (
        select ID_DATE_KEY,
            ACCOUNT_ID as ACCOUNT_ID,
            trim(ACCOUNT_SOURCE) as ACCOUNT_SOURCE,
            EXTERNAL_ACCOUNT_ID as EXTERNAL_ACCOUNT_ID,
            trim(NAME) as NAME,
            trim(TYPE) as TYPE,
            trim(RECORD_TYPE_NAME_C) as RECORD_TYPE_NAME_C,
            PARENT_ID as PARENT_ID,
            trim(PARENT_COMPANY) as PARENT_COMPANY,
            trim(INDUSTRY) as INDUSTRY,
            try_cast(NUMBER_OF_EMPLOYEES as int) as NUMBER_OF_EMPLOYEES,
            cast(ANNUAL_REVENUE as number) as ANNUAL_REVENUE,
            trim(WEBSITE) as WEBSITE,
            trim(BILLING_STREET) as BILLING_STREET,
            trim(BILLING_CITY) as BILLING_CITY,
            trim(BILLING_STATE) as BILLING_STATE,
            try_cast(BILLING_POSTAL_CODE as int) as BILLING_POSTAL_CODE,
            trim(BILLING_COUNTRY) as BILLING_COUNTRY,
            trim(SHIPPING_STREET) as SHIPPING_STREET,
            trim(SHIPPING_CITY) as SHIPPING_CITY,
            trim(SHIPPING_STATE) as SHIPPING_STATE,
            try_cast(SHIPPING_POSTAL_CODE as int) as SHIPPING_POSTAL_CODE,
            trim(SHIPPING_COUNTRY) as SHIPPING_COUNTRY,
            trim(OWNER_ID) as OWNER_ID,
            trim(PHONE) as PHONE,
            trim(SITE_ADDRESS_SAME_AS_BILLING_C) as SITE_ADDRESS_SAME_AS_BILLING_C,
            CREATED_DATE as CREATED_DATE,
            CREATED_BY_ID as CREATED_BY_ID,
            cast(LAST_MODIFIED_DATE as timestamp_ntz) as LAST_MODIFIED_DATE,
            trim(LAST_MODIFIED_BY_ID) as LAST_MODIFIED_BY_ID,
            trim(DESCRIPTION) as DESCRIPTION,
            _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
            _FIVETRAN_SYNCED as _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
            CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
            IS_ACTIVE as IS_ACTIVE
        from raw
    )

select *
from cleaned
