{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['salesforce']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'QUOTE_ID'
) }}

select
    TRIM(ID) AS QUOTE_ID,
    TRIM(OPPORTUNITY_ID) AS OPPORTUNITY_ID,
    TRIM(ACCOUNT_ID) AS ACCOUNT_ID,
    TRIM(STATUS) AS STATUS,
    TRY_CAST(QUOTE_NUMBER AS INT) AS QUOTE_NUMBER,
    TRIM(NAME) AS NAME,
    EXPIRATION_DATE,
    TRIM(BILLING_STREET) AS BILLING_STREET,
    TRIM(BILLING_CITY) AS BILLING_CITY,
    TRIM(BILLING_STATE) AS BILLING_STATE,
    TRY_CAST(BILLING_POSTAL_CODE AS INT) AS BILLING_POSTAL_CODE,
    TRIM(BILLING_COUNTRY) AS BILLING_COUNTRY,
    TRIM(SHIPPING_STREET) AS SHIPPING_STREET,
    TRIM(SHIPPING_CITY) AS SHIPPING_CITY,
    TRIM(SHIPPING_STATE) AS SHIPPING_STATE,
    TRY_CAST(SHIPPING_POSTAL_CODE AS INT) AS SHIPPING_POSTAL_CODE,
    TRIM(SHIPPING_COUNTRY) AS SHIPPING_COUNTRY,
    DISCOUNT,
    CAST(GRAND_TOTAL AS NUMBER) AS GRAND_TOTAL,
    CREATED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    TRIM(OWNER_ID) AS OWNER_ID,
    TRIM(PRICEBOOK_2_ID) AS PRICEBOOK_2_ID,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
from {{ get_raw_source(company, sourcesystem, 'QUOTE') }}
    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
