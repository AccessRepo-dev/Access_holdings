{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_COMPANY',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_LEAD') }}
    
    {% if is_incremental() %}
        where 
            _FIVETRAN_SYNCED > (
                select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
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
    CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'MMDDYYYY')) as ID_DATE_KEY,    
    ID AS HS_LEAD_ID,
    CAST(TRIM(PROPERTY_HUBSPOT_OWNER_ID) AS INT) AS PROPERTY_HUBSPOT_OWNER_ID,
    
    INITCAP(TRIM(PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME)) AS PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME,
    INITCAP(TRIM(PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME)) AS PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME,
    
    LOWER(TRIM(PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL)) AS PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL,
    
    UPPER(TRIM(PROPERTY_HS_LEAD_SOURCE)) AS PROPERTY_HS_LEAD_SOURCE,
    
    TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_HS_CREATEDATE)) AS PROPERTY_HS_CREATEDATE,
    TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_HS_LASTMODIFIEDDATE)) AS PROPERTY_HS_LASTMODIFIEDDATE,
    _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
    from source
)

select * from cleaned
