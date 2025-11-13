
{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem') | lower in ['hubspot', 'hubspot_pawville'] and var('company') | lower in ['wagway', 'playfly','amh'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_USERS',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select *
    from {{ source_snapshot_schema(company, 'HUBSPOT_USERS') }}
    
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
        CAST(ID AS NUMBER) AS ID,
        TRIM(EMAIL) AS EMAIL,
        TRIM(FIRST_NAME) AS FIRST_NAME,
        TRIM(LAST_NAME) AS LAST_NAME,
        CAST(ROLE_ID AS INT) AS ROLE_ID,
          _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
    from source
)

select * from cleaned

