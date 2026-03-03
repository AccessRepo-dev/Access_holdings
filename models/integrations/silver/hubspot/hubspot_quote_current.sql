{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "hubspot") | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower)
        in ["hubspot"]
        and (var("company", "amh") | lower) in ["amh"],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_QUOTE',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select  CONCAT(ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) AS ID_DATE_KEY, 
            {{ hs_canonical_quote(company, sourcesystem) }}, 
            _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            DBT_VALID_FROM,
            DBT_VALID_TO,
            CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE
    from {{ ref('hubspot_quote_snapshot') }}
    
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
        ID AS ID,
        PROPERTY_HS_TITLE AS PROPERTY_HS_TITLE,
        PROPERTY_HS_QUOTE_AMOUNT AS PROPERTY_HS_QUOTE_AMOUNT,
        PROPERTY_HS_STATUS AS PROPERTY_HS_STATUS,
        PROPERTY_HS_PAYMENT_STATUS AS PROPERTY_HS_PAYMENT_STATUS,
        CAST(PROPERTY_HS_LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS PROPERTY_HS_LASTMODIFIEDDATE,
        _FIVETRAN_SYNCED AS _FIVETRAN_SYNCED,
        SILVER_LOAD_DATE::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        IS_ACTIVE AS IS_ACTIVE
    from source
)

select * from cleaned
