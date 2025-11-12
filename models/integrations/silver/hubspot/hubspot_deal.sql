
 {% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}
 
{{ config(
    enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_DEAL',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}
 
with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_DEAL') }}
   
    {% if is_incremental() %}
        where
            PROPERTY_HS_LASTMODIFIEDDATE > (
                select coalesce(max(PROPERTY_HS_LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz)
                from {{ this }}
            )
            and 1=1
            --DBT_VALID_TO is null
    {% else %}
        where 1=1
        --DBT_VALID_TO is null
    {% endif %}
),

cleaned as (
    select
        CONCAT(DEAL_ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'MMDDYYYY')) as ID_DATE_KEY,  
        CAST(DEAL_ID AS NUMBER) AS DEAL_ID,
        TRIM(PROPERTY_DEALNAME) AS PROPERTY_DEALNAME,
        CAST(TRIM(PROPERTY_AMOUNT) AS FLOAT) AS PROPERTY_AMOUNT,
        TRIM(DEAL_PIPELINE_ID) AS DEAL_PIPELINE_ID,
        TRIM(DEAL_PIPELINE_STAGE_ID) AS DEAL_PIPELINE_STAGE_ID,
        CAST(TRIM(PROPERTY_CLOSEDATE) AS TIMESTAMP_NTZ) AS PROPERTY_CLOSEDATE,
        CAST(TRIM(PROPERTY_CREATEDATE) AS TIMESTAMP_NTZ) AS PROPERTY_CREATEDATE,
        CAST(TRIM(PROPERTY_HS_CREATEDATE) AS TIMESTAMP_NTZ) AS PROPERTY_HS_CREATEDATE,
        CAST(TRIM(PROPERTY_HS_LASTMODIFIEDDATE) AS TIMESTAMP_NTZ) AS PROPERTY_HS_LASTMODIFIEDDATE,
        CAST(TRIM(OWNER_ID) AS NUMBER) AS OWNER_ID,
        TRIM(PROPERTY_HS_ALL_OWNER_IDS) AS PROPERTY_HS_ALL_OWNER_IDS,
        TRIM(PROPERTY_DEALTYPE) AS PROPERTY_DEALTYPE,
        CAST(TRIM(PROPERTY_HS_FORECAST_AMOUNT) AS FLOAT) AS PROPERTY_HS_FORECAST_AMOUNT,
        CAST(TRIM(PROPERTY_HS_DEAL_STAGE_PROBABILITY) AS FLOAT) AS PROPERTY_HS_DEAL_STAGE_PROBABILITY

        {% if company | lower != 'amh' %}
        , TRIM(PROPERTY_DESCRIPTION) AS PROPERTY_DESCRIPTION

        {% endif %}

        {% if sourcesystem == 'HUBSPOT_PAWVILLE' %}
        , NULL AS PROPERTY_CLUB_C
        , NULL AS PROPERTY_SERVICE_TYPE
        {% elif company | lower == 'wagway' and  sourcesystem == 'HUBSPOT' %}
        , TRIM(PROPERTY_CLUB_C) AS PROPERTY_CLUB_C
        , TRIM(PROPERTY_SERVICE_TYPE) AS PROPERTY_SERVICE_TYPE
        {% endif %}

        , CAST(TRIM(PROPERTY_HS_PROJECTED_AMOUNT) AS FLOAT) AS PROPERTY_HS_PROJECTED_AMOUNT

        {% if company | lower != 'amh' %}
        , CAST(PROPERTY_INVOICE_ID AS NUMBER) AS PROPERTY_INVOICE_ID
        {% endif %}
        ,CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
        ,CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM
        ,CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO
        ,CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
    from source
)
select * from cleaned
