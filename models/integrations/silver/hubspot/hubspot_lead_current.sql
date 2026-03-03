{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "hubspot") | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower)
        in ["hubspot"]
        and (var("company", "wagway") | lower) in ["wagway", "playfly"],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_LEAD',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select CONCAT(ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) AS ID_DATE_KEY, 
            {{ hs_canonical_lead(company, sourcesystem) }}, 
            _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            DBT_VALID_FROM,
            DBT_VALID_TO,
            CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE
    from {{ ref('hubspot_lead_snapshot') }}
    
    {% if is_incremental() %}
        where 
           (_FIVETRAN_SYNCED > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01')) from {{ this }})
        OR 
            (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
    {% else %}
        where 1=1
    {% endif %}
),

cleaned as (
    select ID_DATE_KEY AS ID_DATE_KEY,    
        HS_LEAD_ID AS HS_LEAD_ID,
        CAST(TRIM(PROPERTY_HUBSPOT_OWNER_ID) AS INT) AS PROPERTY_HUBSPOT_OWNER_ID,
        
        INITCAP(TRIM(PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME)) AS PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME,
        INITCAP(TRIM(PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME)) AS PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME,
        
        LOWER(TRIM(PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL)) AS PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL,
        
        UPPER(TRIM(PROPERTY_HS_LEAD_SOURCE)) AS PROPERTY_HS_LEAD_SOURCE,
        
        TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_HS_CREATEDATE)) AS PROPERTY_HS_CREATEDATE,
        TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_HS_LASTMODIFIEDDATE)) AS PROPERTY_HS_LASTMODIFIEDDATE,
        _FIVETRAN_SYNCED AS _FIVETRAN_SYNCED,
        SILVER_LOAD_DATE::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        IS_ACTIVE AS IS_ACTIVE
    from source
)

select * from cleaned
