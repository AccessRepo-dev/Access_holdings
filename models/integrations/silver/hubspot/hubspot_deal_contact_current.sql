{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
    enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot", "hubspot_pawville"]
    and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~'_DEAL_CONTACT',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}


with raw as (
    select CONCAT(DEAL_ID,'_',CONTACT_ID,'_',TYPE_ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) AS ID_DATE_KEY, 
            {{ hs_canonical_deal_contact(company, sourcesystem) }}, 
            _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            DBT_VALID_FROM,
            DBT_VALID_TO,
            CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS is_active
    FROM  {{ ref('hubspot_deal_contact_snapshot') }}
    
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
    SELECT
        ID_DATE_KEY AS ID_DATE_KEY,
        DEAL_ID AS DEAL_ID,
        CATEGORY AS CATEGORY,
        CONTACT_ID AS CONTACT_ID,
        TYPE_ID AS TYPE_ID,
        _FIVETRAN_SYNCED AS _FIVETRAN_SYNCED,
        SILVER_LOAD_DATE AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        IS_ACTIVE AS IS_ACTIVE
    from raw
)

select * from cleaned
