{% if false %}

{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~'_DEAL_CONTACT',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}


with raw as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_CONTACT') }}
    
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
SELECT

        CONCAT(DEAL_ID,'_','CONTACT_ID','_',TO_VARCHAR(DBT_VALID_FROM, 'MMDDYYYY')) as ID_DATE_KEY,   
    CAST(DEAL_ID AS BIGINT) AS DEAL_ID, 
    CAST(CONTACT_ID AS BIGINT) AS CONTACT_ID,
    _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
from raw
)

select * from cleaned

{% endif %}