
{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem') | lower in ['hubspot','hubspot_pawville'] and var('company') | lower in ['wagway', 'playfly','amh'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_DEAL_PIPELINE',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}


with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_DEAL_PIPELINE') }}
    
    {% if is_incremental() %}
        where 
            UPDATED_AT > (
                select dateadd(day, -1, coalesce(max(UPDATED_AT), '1900-01-01'))
                from {{ this }}
            )
            and 1=1
    {% else %}
        where 1=1
    {% endif %}
),

cleaned as (
    select
        CONCAT(PIPELINE_ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,   
        TRIM(PIPELINE_ID) AS PIPELINE_ID,
        TRIM(LABEL) AS LABEL,
        _FIVETRAN_SYNCED,
        DISPLAY_ORDER,
        CAST(CREATED_AT AS TIMESTAMP_NTZ) AS CREATED_AT,
        CAST(UPDATED_AT AS TIMESTAMP_NTZ) AS UPDATED_AT,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
    from source
)

select * from cleaned
