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

select
    ID,
    PROPERTY_FIRSTNAME,
    PROPERTY_LASTNAME,
    PROPERTY_EMAIL,
    PROPERTY_PHONE, 
    PROPERTY_MOBILEPHONE,
    PROPERTY_LIFECYCLESTAGE,
    PROPERTY_HUBSPOT_OWNER_ID,
    PROPERTY_COMPANY,
    PROPERTY_JOBTITLE,
    PROPERTY_CREATEDATE,
    PROPERTY_HS_LASTMODIFIEDDATE,
    PROPERTY_HS_LEAD_STATUS,
    PROPERTY_ADDRESS,
    PROPERTY_CITY,
    PROPERTY_STATE,
    PROPERTY_COUNTRY,
    PROPERTY_FAX,
    PROPERTY_HS_TIMEZONE
from {{ get_raw_source(company, sourcesystem, 'CONTACT') }}
    {% if is_incremental() %}
    where PROPERTY_HS_LASTMODIFIEDDATE > (
        select coalesce(max(PROPERTY_HS_LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
