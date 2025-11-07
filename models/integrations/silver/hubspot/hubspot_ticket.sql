{% set company = var('company') %} 
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot']) }}



{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias =  sourcesystem ~ '_TICKET',
    incremental_strategy = 'merge',
    unique_key = 'PROPERTY_HS_TICKET_ID'
) }}

SELECT
    CAST(TRIM(PROPERTY_HS_TICKET_ID) AS INT) AS TICKET_ID,
    TRIM(PROPERTY_DESCRIPTION) AS DESCRIPTION,
    TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_CREATEDATE)) AS CREATED_DATE,
    TRY_TO_TIMESTAMP_NTZ(NULLIF(TRIM(PROPERTY_CLOSEDDATE), '')) AS CLOSED_DATE,
    (TRIM(PROPERTY_HS_PIPELINE)) AS PIPELINE_ID,
    (TRIM(PROPERTY_HS_PIPELINE_STAGE)) AS PIPELINE_STAGE_ID,
    UPPER(TRIM(PROPERTY_HS_TICKET_PRIORITY)) AS TICKET_PRIORITY,
    UPPER(TRIM(PROPERTY_HS_OBJECT_SOURCE)) AS OBJECT_SOURCE,
    _FIVETRAN_SYNCED
from {{ get_raw_source(company, sourcesystem, 'TICKET') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
