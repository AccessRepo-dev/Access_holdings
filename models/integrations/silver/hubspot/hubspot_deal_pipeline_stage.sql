{% if false %}

{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~ '_DEAL_PIPELINE_STAGE',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}


with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_DEAL_PIPELINE_STAGE') }}
    
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
        CONCAT(STAGE_ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'MMDDYYYY')) as ID_DATE_KEY,   
    CAST(STAGE_ID AS varchar) AS STAGE_ID,
    TRIM(LABEL) AS LABEL,
    CAST(PIPELINE_ID AS varchar) AS PIPELINE_ID,
    CAST(PROBABILITY AS FLOAT) AS PROBABILITY, 
    _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
from raw
)

select * from cleaned


{% endif %}