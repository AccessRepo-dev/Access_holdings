
{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem') | lower in ['hubspot','hubspot_pawville'] and var('company') | lower in ['wagway', 'playfly','amh'],
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~'_DEAL_CONTACT',
    incremental_strategy = 'merge',
    unique_key = 'UNIQUE_ID'
) }}


with raw as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_DEAL_CONTACT') }}
    
    {% if is_incremental() %}
        where 
            _FIVETRAN_SYNCED > (
                select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
                from {{ this }}
            )
            and 1=1
    {% else %}
        where 1=1
    {% endif %}
),

cleaned as (
    SELECT
        HASH(DEAL_ID,'_',CONTACT_ID,'_',TYPE_ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'MMDDYYYY')) AS UNIQUE_ID,
        DEAL_ID,
        CATEGORY,
        CONTACT_ID,
        TYPE_ID,
        _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE
    from raw
)

select * from cleaned
