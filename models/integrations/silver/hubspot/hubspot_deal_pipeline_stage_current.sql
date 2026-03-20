{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
    enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot", "hubspot_pawville"]
    and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~ '_DEAL_PIPELINE_STAGE',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}


with source as (
    select CONCAT(STAGE_ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) AS ID_DATE_KEY, 
            {{ hs_canonical_deal_pipeline_stage(company, sourcesystem) }}, 
            _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            DBT_VALID_FROM,
            DBT_VALID_TO,
            CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE
    from  {{ ref('hubspot_deal_pipeline_stage_snapshot') }}
    
    {% if is_incremental() %}
        where 
            (UPDATED_AT > (select dateadd(day, -3, coalesce(max(UPDATED_AT), '1900-01-01')) from {{ this }})
        OR 
            (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
    {% else %}
        where 1=1
    {% endif %}
),

cleaned as (
    select ID_DATE_KEY AS ID_DATE_KEY,   
        CAST(STAGE_ID AS varchar) AS STAGE_ID,
        TRIM(LABEL) AS LABEL,
        CAST(PIPELINE_ID AS varchar) AS PIPELINE_ID,
        CAST(PROBABILITY AS FLOAT) AS PROBABILITY, 
        IS_CLOSED AS IS_CLOSED,
        TRIM(WRITE_PERMISSIONS) AS WRITE_PERMISSIONS ,
        DISPLAY_ORDER AS DISPLAY_ORDER,
        CAST(CREATED_AT AS TIMESTAMP_NTZ) AS CREATED_AT,
        CAST(UPDATED_AT AS TIMESTAMP_NTZ) AS UPDATED_AT,
        _FIVETRAN_SYNCED AS _FIVETRAN_SYNCED,
        SILVER_LOAD_DATE::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        IS_ACTIVE AS IS_ACTIVE
from source
)

select * from cleaned

