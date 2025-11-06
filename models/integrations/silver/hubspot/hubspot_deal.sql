{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_DEAL',
    incremental_strategy = 'merge',
    unique_key = 'DEAL_ID'
) }}

with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_DEAL') }}
    
    {% if is_incremental() %}
        where 
            _FIVETRAN_SYNCED > (
                select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
                from {{ this }}
            )
            and DBT_VALID_TO is null
    {% else %}
        where DBT_VALID_TO is null
    {% endif %}
),

cleaned as (
    select
        CAST(DEAL_ID AS NUMBER) AS DEAL_ID,
        TRIM(PROPERTY_DEALNAME) AS PROPERTY_DEALNAME,
        CAST(TRIM(PROPERTY_AMOUNT) AS FLOAT) AS PROPERTY_AMOUNT,
        TRIM(DEAL_PIPELINE_ID)  AS DEAL_PIPELINE_ID,
        TRIM(DEAL_PIPELINE_STAGE_ID)  AS DEAL_PIPELINE_STAGE_ID,
        CAST(TRIM(PROPERTY_CLOSEDATE) AS TIMESTAMP_NTZ) AS PROPERTY_CLOSEDATE,
        CAST(TRIM(PROPERTY_CREATEDATE) AS TIMESTAMP_NTZ) AS PROPERTY_CREATEDATE,
        CAST(TRIM(PROPERTY_HS_CREATEDATE) AS TIMESTAMP_NTZ) AS PROPERTY_HS_CREATEDATE,
        CAST(TRIM(PROPERTY_HS_LASTMODIFIEDDATE) AS TIMESTAMP_NTZ) AS PROPERTY_HS_LASTMODIFIEDDATE,
        CAST(TRIM(OWNER_ID) AS NUMBER) AS OWNER_ID,
        TRIM(PROPERTY_HS_ALL_OWNER_IDS) AS PROPERTY_HS_ALL_OWNER_IDS,
        TRIM(PROPERTY_DEALTYPE) AS PROPERTY_DEALTYPE,
        CAST(TRIM(PROPERTY_HS_FORECAST_AMOUNT) AS FLOAT) AS PROPERTY_HS_FORECAST_AMOUNT,
        CAST(TRIM(PROPERTY_HS_DEAL_STAGE_PROBABILITY) AS FLOAT) AS PROPERTY_HS_DEAL_STAGE_PROBABILITY,
        TRIM(PROPERTY_DESCRIPTION) AS PROPERTY_DESCRIPTION
    from source
)

select * from cleaned


