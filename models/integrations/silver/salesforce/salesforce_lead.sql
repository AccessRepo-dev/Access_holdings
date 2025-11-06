{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['salesforce']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'LEAD_ID'
) }}

select
    TRIM(ID) AS LEAD_ID,
    TRIM(OWNER_ID) AS OWNER_ID,
    TRIM(COMPANY) AS COMPANY,
    TRIM(FIRST_NAME) AS FIRST_NAME,
    TRIM(LAST_NAME) AS LAST_NAME,
    TRIM(SALUTATION) AS SALUTATION,
    TRIM(TITLE) AS TITLE,
    EMAIL,
    PHONE,
    MOBILE_PHONE,
    WEBSITE,
    TRIM(LEAD_SOURCE) AS LEAD_SOURCE,
    TRIM(STATUS) AS STATUS,
    TRIM(RATING) AS RATING,
    TRIM(INDUSTRY) AS INDUSTRY,
    TRY_CAST(NUMBER_OF_EMPLOYEES AS INT) AS NUMBER_OF_EMPLOYEES,
    TRIM(STREET) AS STREET,
    TRIM(CITY) AS CITY,
    TRIM(STATE) AS STATE,
    TRY_CAST(NUMBER_OF_EMPLOYEES AS INT) AS POSTAL_CODE,
    TRIM(COUNTRY) AS COUNTRY,
    CONVERTED_DATE,
    TRIM(CONVERTED_ACCOUNT_ID) AS CONVERTED_ACCOUNT_ID,
    TRIM(CONVERTED_CONTACT_ID) AS CONVERTED_CONTACT_ID,
    TRIM(CONVERTED_OPPORTUNITY_ID) AS CONVERTED_OPPORTUNITY_ID,
    IS_CONVERTED,
    CREATED_DATE,
    TRIM(CREATED_BY_ID) AS CREATED_BY_ID,
    LAST_MODIFIED_DATE,
    TRIM(LAST_MODIFIED_BY_ID) AS LAST_MODIFIED_BY_ID,
    TRIM(DESCRIPTION) AS DESCRIPTION,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
from {{ get_raw_source(company, sourcesystem, 'LEAD') }}
    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
