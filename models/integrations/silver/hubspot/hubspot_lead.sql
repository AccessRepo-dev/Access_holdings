{% set company = var('company') %} --wagway , playfly
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = 'LEAD',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

select
    TRY_TO_NUMBER(TRIM(PROPERTY_HUBSPOT_OWNER_ID)) AS PROPERTY_HUBSPOT_OWNER_ID,
    
    INITCAP(TRIM(PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME)) AS PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME,
    INITCAP(TRIM(PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME)) AS PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME,
    
    LOWER(TRIM(PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL)) AS PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL,
    
    UPPER(TRIM(PROPERTY_HS_LEAD_SOURCE)) AS PROPERTY_HS_LEAD_SOURCE,
    
    TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_HS_CREATEDATE)) AS PROPERTY_HS_CREATEDATE,
    TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_HS_LASTMODIFIEDDATE)) AS PROPERTY_HS_LASTMODIFIEDDATE,
    _FIVETRAN_SYNCED

    
from {{ get_raw_source(company, sourcesystem, 'LEAD') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
