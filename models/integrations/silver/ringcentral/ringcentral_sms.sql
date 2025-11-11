{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['ringcentral']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'SMS') }}
{% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )

{% endif %}

),

cleaned as 
(
    select
        CAST(ID AS BIGINT) AS id,
        TRIM(BATCH_ID) AS batch_id,
        CAST(CREATION_TIME AS TIMESTAMP_TZ) AS creation_time,
        CAST(LAST_MODIFIED_TIME AS TIMESTAMP_TZ) AS last_modified_time,
        TRIM(MESSAGE_STATUS) AS message_status,
        CAST(SEGMENT_COUNT AS INTEGER) AS segment_count,
        TRIM(TEXT) AS text,
        CAST(COST AS DECIMAL(10,2)) AS cost,
        TRIM(DIRECTION) AS direction,
        TRIM(ERROR_CODE) AS error_code,
        TRIM("FROM") AS from_phone,
        CAST(_FIVETRAN_SYNCED AS TIMESTAMP_TZ) AS _fivetran_synced,
        'PUPS Pets Club' AS COMPANY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
