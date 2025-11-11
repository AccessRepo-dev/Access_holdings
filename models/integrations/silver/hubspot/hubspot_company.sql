{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_COMPANY',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_COMPANY') }}
    
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
        CAST(ID AS NUMBER) AS ID,
        TRIM(PROPERTY_NAME) AS PROPERTY_NAME,
        {%if sourcesystem == 'HUBSPOT'%}
            TRIM(PROPERTY_DOMAIN) AS PROPERTY_DOMAIN,
             TRIM(PROPERTY_PHONE) AS PROPERTY_PHONE,
        {%endif%}
       
        TRIM(PROPERTY_INDUSTRY) AS PROPERTY_INDUSTRY,
        TRIM(PROPERTY_ADDRESS) AS PROPERTY_ADDRESS,
        TRIM(PROPERTY_CITY) AS PROPERTY_CITY,
        TRIM(PROPERTY_STATE) AS PROPERTY_STATE,
        TRIM(PROPERTY_COUNTRY) AS PROPERTY_COUNTRY,
        CAST(TRIM(PROPERTY_HUBSPOT_OWNER_ID) AS NUMBER) AS PROPERTY_HUBSPOT_OWNER_ID,
        CAST(TRIM(PROPERTY_CREATEDATE) AS TIMESTAMP_NTZ) AS PROPERTY_CREATEDATE,
        CAST(TRIM(PROPERTY_HS_LASTMODIFIEDDATE) AS TIMESTAMP_NTZ) AS PROPERTY_HS_LASTMODIFIEDDATE,

        {% if company | lower not in ['amh', 'playfly'] %}
            TRIM(PROPERTY_COMPANY_TYPE) AS PROPERTY_COMPANY_TYPE,
        {% endif %}

        CAST(TRIM(PROPERTY_ANNUALREVENUE) AS FLOAT) AS PROPERTY_ANNUALREVENUE,
        CAST(TRIM(PROPERTY_NUMBEROFEMPLOYEES) AS NUMBER) AS PROPERTY_NUMBEROFEMPLOYEES,
        _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source
)

select * from cleaned
