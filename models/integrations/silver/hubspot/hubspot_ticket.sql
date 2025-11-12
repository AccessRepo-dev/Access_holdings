{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = var('sourcesystem', 'none') in ['hubspot'],
    database = get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~ '_TICKET',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

WITH src AS (
    SELECT
        CAST(TRIM(ID) AS INT) AS TICKET_ID,
        TRIM(PROPERTY_HS_TICKET_ID) AS PROPERTY_HS_TICKET_ID,
        --TRIM(PROPERTY_DESCRIPTION) AS DESCRIPTION,
        TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_CREATEDATE)) AS CREATED_DATE,
        --TRY_TO_TIMESTAMP_NTZ(NULLIF(TRIM(PROPERTY_CLOSEDDATE), '')) AS CLOSED_DATE,
        TRIM(PROPERTY_HS_PIPELINE) AS PIPELINE_ID,
        TRIM(PROPERTY_HS_PIPELINE_STAGE) AS PIPELINE_STAGE_ID,
        --UPPER(TRIM(PROPERTY_HS_TICKET_PRIORITY)) AS TICKET_PRIORITY,
        UPPER(TRIM(PROPERTY_HS_OBJECT_SOURCE)) AS OBJECT_SOURCE,
        TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_HS_LASTMODIFIEDDATE)) AS PROPERTY_HS_LASTMODIFIEDDATE
        --,_FIVETRAN_SYNCED
    FROM {{ get_raw_source(company, sourcesystem, 'TICKET') }}
)

SELECT *
FROM src
{% if is_incremental() %}
WHERE PROPERTY_HS_LASTMODIFIEDDATE > (
    SELECT COALESCE(MAX(PROPERTY_HS_LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz)
    FROM {{ this }}
)
{% endif %}


/*

{% set company = var('company') %} --wagway , playfly
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot']) }}



{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias =  sourcesystem ~ '_TICKET',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

SELECT
    CAST(TRIM(ID) AS INT) AS TICKET_ID,
    
    {% if company | lower != 'playfly' %}
        TRIM(PROPERTY_DESCRIPTION) AS DESCRIPTION,
    {% endif %}

    TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_CREATEDATE)) AS CREATED_DATE,

    {% if company | lower != 'playfly' %}
        TRY_TO_TIMESTAMP_NTZ(NULLIF(TRIM(PROPERTY_CLOSEDDATE), '')) AS CLOSED_DATE,
    {% endif %}

    --TRIM(PROPERTY_HS_PIPELINE) AS PIPELINE_ID,
    TRIM(PROPERTY_HS_PIPELINE_STAGE) AS PIPELINE_STAGE_ID,

    {% if company | lower != 'playfly' %}
        UPPER(TRIM(PROPERTY_HS_TICKET_PRIORITY)) AS TICKET_PRIORITY,
    {% endif %}

    UPPER(TRIM(PROPERTY_HS_OBJECT_SOURCE)) AS OBJECT_SOURCE,
    TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_HS_LASTMODIFIEDDATE)) AS PROPERTY_HS_LASTMODIFIEDDATE

from {{ get_raw_source(company, sourcesystem, 'TICKET') }}
    {% if is_incremental() %}
    where PROPERTY_HS_LASTMODIFIEDDATE > (
        select coalesce(max(PROPERTY_HS_LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
   -- or _FIVETRAN_DELETED = true
    {% endif %}

*/