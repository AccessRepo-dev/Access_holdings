{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_DEAL_PIPELINE',
    incremental_strategy = 'merge',
    unique_key = 'PIPELINE_ID'
) }}

with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_DEAL_PIPELINE') }}
    
    {% if is_incremental() %}
        where 
            _FIVETRAN_SYNCED > (
                select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
                from {{ this }}
            )
            and DBT_VALID_TO is null
    {% else %}
        where DBT_VALID_TO is null
    {% endif %}
),

cleaned as (
    select
        TRIM(PIPELINE_ID) AS PIPELINE_ID,
        TRIM(LABEL) AS LABEL,
        _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source
)

select * from cleaned
