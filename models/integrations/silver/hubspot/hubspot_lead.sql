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
    PROPERTY_HUBSPOT_OWNER_ID ,
    PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME ,
    PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME ,
    PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL , 
    PROPERTY_HS_LEAD_SOURCE ,
    PROPERTY_HS_CREATEDATE ,
    PROPERTY_HS_LASTMODIFIEDDATE

    
from {{ get_raw_source(company, sourcesystem, 'LEAD') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
