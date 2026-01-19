{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_company',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (

    select
        ID_DATE_KEY,
        ACCOUNT_ID as ID,
        NAME,
        null as DOMAIN,
        PHONE as PHONE,
        INDUSTRY,
        SITE_ADDRESS_SAME_AS_BILLING_C as ADDRESS,
        BILLING_CITY as CITY,
        BILLING_STATE as STATE,
        BILLING_COUNTRY as COUNTRY,
        OWNER_ID,
        CREATED_DATE as CREATE_DATE,
        LAST_MODIFIED_DATE,
        TYPE as PROPERTY_COMPANY_TYPE,
        annual_revenue as ANNUAL_REVENUE,
        NUMBER_OF_EMPLOYEES,

        -- BILLING_CITY,
        -- SHIPPING_CITY,
        -- CREATED_DATE,
        -- LAST_MODIFIED_DATE,
        -- DBT_VALID_FROM,
        -- DBT_VALID_TO,
        -- Is_Active,
        CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from {{ get_silver_source(company, 'SALESFORCE_ACCOUNT') }}
    where Is_Active = 1
    {% if is_incremental() %}
        and LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}
)
select *    
from source