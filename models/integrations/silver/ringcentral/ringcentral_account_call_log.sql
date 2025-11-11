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
from {{ get_raw_source(company, sourcesystem, 'ACCOUNT_CALL_LOG') }}
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
    TRIM(ID),
    CAST(START_TIME AS TIMESTAMP_NTZ),
    CAST(TRIM(DURATION) AS INT),
    CAST(TRIM(DURATION_MS) AS INT),
    TRIM(TYPE),
    TRIM(INTERNAL_TYPE),
    TRIM(DIRECTION),
    TRIM(ACTION),
    TRIM(RESULT),
    TRIM(REASON),
    TRIM(REASON_DESCRIPTION),
    CAST(TRIM(ACCOUNT_ID) AS BIGINT),
    CAST(TRIM(SESSION_ID) AS BIGINT),
    TRIM(FROM_PHONE_NUMBER),
    CAST(TRIM(FROM_EXTENSION_NUMBER) AS INT),
    CAST(TRIM(FROM_EXTENSION_ID) AS BIGINT),
    TRIM(FROM_LOCATION),
    TRIM(FROM_NAME),
    TRIM(FROM_DIALED_PHONE_NUMBER),
    TRIM(TO_PHONE_NUMBER),
    CAST(TRIM(TO_EXTENSION_NUMBER) AS INT),
    CAST(TRIM(TO_EXTENSION_ID) AS BIGINT),
    TRIM(TO_LOCATION),
    TRIM(TO_NAME),
    TRIM(TO_DIALED_PHONE_NUMBER),
    CAST(TRIM(EXTENSION_ID) AS BIGINT),
    'PUPS Pets Club' AS COMPANY,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
