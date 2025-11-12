{% set company = var('company') %} 
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot']) }}
{{ config(enabled = var('company', 'none') in ['AMH']) }}



{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias =  sourcesystem ~ '_QUOTE',
    incremental_strategy = 'merge',
    unique_key = 'QUOTE_ID'
) }}

SELECT
    ID AS QUOTE_ID,   
    INITCAP(TRIM(PROPERTY_HS_SENDER_COMPANY_NAME)) AS PROPERTY_HS_SENDER_COMPANY_NAME,
    PROPERTY_HS_QUOTE_AMOUNT,
    TRIM(PROPERTY_HS_QUOTE_PROGRESSION_STATUS) AS PROPERTY_HS_QUOTE_PROGRESSION_STATUS,
    TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_HS_CREATEDATE)) AS PROPERTY_HS_CREATEDATE,
    TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_HS_LASTMODIFIEDDATE)) AS PROPERTY_HS_LASTMODIFIEDDATE,
    _FIVETRAN_SYNCED

from {{ get_raw_source(company, sourcesystem, 'QUOTE') }}
    {% if is_incremental() %}
    where PROPERTY_HS_LASTMODIFIEDDATE > (
        select coalesce(max(PROPERTY_HS_LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
   -- or _FIVETRAN_DELETED = true
    {% endif %}
