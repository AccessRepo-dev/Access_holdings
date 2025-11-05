{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = 'CONTACT',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}


SELECT
    TRY_TO_NUMBER(TRIM(ID)) AS ID,
    INITCAP(TRIM(PROPERTY_FIRSTNAME)) AS PROPERTY_FIRSTNAME,
    INITCAP(TRIM(PROPERTY_LASTNAME)) AS PROPERTY_LASTNAME,
    LOWER(TRIM(PROPERTY_EMAIL)) AS PROPERTY_EMAIL,
    
    -- Clean phone numbers (remove spaces, parentheses, dashes)
    REGEXP_REPLACE(TRIM(PROPERTY_PHONE), '[^0-9]', '') AS PROPERTY_PHONE,
    REGEXP_REPLACE(TRIM(PROPERTY_MOBILEPHONE), '[^0-9]', '') AS PROPERTY_MOBILEPHONE,
    
    -- Lifecycle stage normalized to lowercase
    LOWER(TRIM(PROPERTY_LIFECYCLESTAGE)) AS PROPERTY_LIFECYCLESTAGE,
    
    TRY_TO_NUMBER(TRIM(PROPERTY_HUBSPOT_OWNER_ID)) AS PROPERTY_HUBSPOT_OWNER_ID,
    
    --  job title properly cased

    INITCAP(TRIM(PROPERTY_JOBTITLE)) AS PROPERTY_JOBTITLE,
    
    -- Cast and standardize dates
    TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_CREATEDATE)) AS PROPERTY_CREATEDATE,
    
    LOWER(TRIM(PROPERTY_HS_LEAD_STATUS)) AS PROPERTY_HS_LEAD_STATUS,
    
    -- Address cleanup
    INITCAP(TRIM(PROPERTY_ADDRESS)) AS PROPERTY_ADDRESS,
    INITCAP(TRIM(PROPERTY_CITY)) AS PROPERTY_CITY,
    INITCAP(TRIM(PROPERTY_STATE)) AS PROPERTY_STATE,
    INITCAP(TRIM(PROPERTY_COUNTRY)) AS PROPERTY_COUNTRY,
    
    REGEXP_REPLACE(TRIM(PROPERTY_FAX), '[^0-9]', '') AS PROPERTY_FAX,
    
    TRIM(PROPERTY_HS_TIMEZONE) AS PROPERTY_HS_TIMEZONE,
    _FIVETRAN_SYNCED
from {{ get_raw_source(company, sourcesystem, 'CONTACT') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
