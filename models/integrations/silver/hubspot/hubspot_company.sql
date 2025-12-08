{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = (var('sourcesystem') | lower) in ['hubspot', 'hubspot_pawville']
             and (var('company') | lower) in ['wagway', 'playfly'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_COMPANY',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_COMPANY') }}
    {% if is_incremental() %}
        where 
            (_FIVETRAN_SYNCED > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01')) from {{ this }})
        OR 
            (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
    {% else %}
        where 1 = 1
    {% endif %}
),

cleaned as (
    select
        CONCAT(ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        CAST(ID AS NUMBER) AS ID,
        INITCAP(TRIM(PROPERTY_NAME)) AS PROPERTY_NAME,

        -- HubSpot-only fields
        {% if sourcesystem == 'HUBSPOT' %}
            TRIM(PROPERTY_DOMAIN) AS PROPERTY_DOMAIN,
            TRIM(PROPERTY_PHONE) AS PROPERTY_PHONE,
            TRIM(PROPERTY_ADDRESS) AS PROPERTY_ADDRESS,
            TRIM(PROPERTY_CITY) AS PROPERTY_CITY,
            TRIM(PROPERTY_STATE) AS PROPERTY_STATE,
            TRIM(PROPERTY_COUNTRY) AS PROPERTY_COUNTRY,
            CAST(PROPERTY_HUBSPOT_OWNER_ID AS NUMBER) AS PROPERTY_HUBSPOT_OWNER_ID,
            CAST(PROPERTY_ANNUALREVENUE AS NUMBER) AS PROPERTY_ANNUALREVENUE,
        {% else %}
            CAST(NULL AS VARCHAR) AS PROPERTY_DOMAIN,
            CAST(NULL AS VARCHAR) AS PROPERTY_PHONE,
            CAST(NULL AS VARCHAR) AS PROPERTY_ADDRESS,
            CAST(NULL AS VARCHAR) AS PROPERTY_CITY,
            CAST(NULL AS VARCHAR) AS PROPERTY_STATE,
            CAST(NULL AS VARCHAR) AS PROPERTY_COUNTRY,
            CAST(NULL AS NUMBER) AS PROPERTY_HUBSPOT_OWNER_ID,
            CAST(NULL AS NUMBER) AS PROPERTY_ANNUALREVENUE,
        {% endif %}

       
        
        CAST(PROPERTY_CREATEDATE AS TIMESTAMP_NTZ) AS PROPERTY_CREATEDATE,
        CAST(PROPERTY_HS_LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS PROPERTY_HS_LASTMODIFIEDDATE,

        -- Company-type field for all except Playfly
        {% if company | lower == 'wagway' and sourcesystem | lower == 'hubspot' %}
            TRIM(PROPERTY_COMPANY_TYPE) AS PROPERTY_COMPANY_TYPE,
        {% else %}
            CAST(NULL AS VARCHAR) AS PROPERTY_COMPANY_TYPE,
        {% endif %}
        CAST(TRIM(PROPERTY_NUMBEROFEMPLOYEES) AS NUMBER) AS PROPERTY_NUMBEROFEMPLOYEES,
        _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE
    from source
)

select *
from cleaned