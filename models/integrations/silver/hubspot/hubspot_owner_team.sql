{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem') | lower in ['hubspot'] and var('company') | lower in ['wagway'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_OWNER_TEAM',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_OWNER_TEAM') }}
    
    {% if is_incremental() %}
        where 
            _FIVETRAN_SYNCED > (
                select dateadd(day, -1, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz))
                from {{ this }} 
            )
            and 1=1

    {% else %}
        where 1=1
    {% endif %}
),

cleaned as (
    select
        CONCAT(OWNER_ID,'_',TEAM_ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,  
        CAST(TRIM(OWNER_ID) AS BIGINT) AS OWNER_ID,
	    CAST(TRIM(TEAM_ID) AS BIGINT) AS TEAM_ID,
	    CAST(TRIM(_FIVETRAN_DELETED) AS BOOLEAN) AS _FIVETRAN_DELETED,
	    CAST(TRIM(IS_TEAM_PRIMARY) AS BOOLEAN) AS IS_TEAM_PRIMARY,
	    CAST(TRIM(_FIVETRAN_SYNCED) AS TIMESTAMP_TZ) AS_FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
    from source
)

select * from cleaned
