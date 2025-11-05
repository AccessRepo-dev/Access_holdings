{% set company = var('company') %} --wagway , playfly
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot']) }}
{{ config(enabled = var('company', 'none') in ['wagway','playfly']) }}


{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = 'TICKET',
    incremental_strategy = 'merge',
    unique_key = 'PROPERTY_HS_TICKET_ID'
) }}

SELECT
   PROPERTY_HS_TICKET_ID,
    PROPERTY_SUBJECT,
    PROPERTY_DESCRIPTION,
    PROPERTY_CREATEDATE,
    PROPERTY_CLOSEDDATE,
    PROPERTY_HS_PIPELINE,
    PROPERTY_HS_PIPELINE_STAGE,
    PROPERTY_HS_TICKET_PRIORITY,
    PROPERTY_HS_OBJECT_SOURCE

from {{ get_raw_source(company, sourcesystem, 'TICKET') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
