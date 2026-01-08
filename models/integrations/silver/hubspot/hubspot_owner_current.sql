{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "hubspot") | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower)
        in ["hubspot", "hubspot_pawville"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_OWNER',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select *
    from {{ ref('hubspot_owner_snapshot') }}
    
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
    select
        CONCAT(OWNER_ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,    
        CAST(TRIM(OWNER_ID) AS INT) AS OWNER_ID,
        INITCAP(TRIM(FIRST_NAME)) AS FIRST_NAME,
        INITCAP(TRIM(LAST_NAME)) AS LAST_NAME,
        LOWER(TRIM(EMAIL)) AS EMAIL,
        _FIVETRAN_SYNCED,
        CAST(UPDATED_AT AS TIMESTAMP_NTZ) AS UPDATED_AT,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
    from source
)

select * from cleaned
