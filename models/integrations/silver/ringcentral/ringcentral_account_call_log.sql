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
    TRIM(ID) AS ID,
    CAST(START_TIME AS TIMESTAMP_NTZ) AS START_TIME,
    CAST(TRIM(DURATION) AS INT) AS DURATION,
    CAST(TRIM(DURATION_MS) AS INT) AS DURATION_MS,
    TRIM(TYPE) AS TYPE,
    TRIM(INTERNAL_TYPE) AS INTERNAL_TYPE,
    TRIM(DIRECTION) AS DIRECTION,
    TRIM(ACTION) AS ACTION,
    TRIM(RESULT), AS RESULT
    TRIM(REASON) AS REASON,
    TRIM(REASON_DESCRIPTION) AS REASON_DESCRIPTION,
    CAST(TRIM(ACCOUNT_ID) AS BIGINT) AS ACCOUNT_ID,
    CAST(TRIM(SESSION_ID) AS BIGINT) AS SESSION_ID,
    TRIM(FROM_PHONE_NUMBER) AS FROM_PHONE_NUMBER,
    CAST(TRIM(FROM_EXTENSION_NUMBER) AS INT) AS FROM_EXTENSION_NUMBER,
    CAST(TRIM(FROM_EXTENSION_ID) AS BIGINT) AS FROM_EXTENSION_ID,
    TRIM(FROM_LOCATION) AS FROM_LOCATION,
    TRIM(FROM_NAME) AS FROM_NAME,
    TRIM(FROM_DIALED_PHONE_NUMBER) AS FROM_DIALED_PHONE_NUMBER,
    TRIM(TO_PHONE_NUMBER) AS TO_PHONE_NUMBER,
    CAST(TRIM(TO_EXTENSION_NUMBER) AS INT) AS TO_EXTENSION_NUMBER,
    CAST(TRIM(TO_EXTENSION_ID) AS BIGINT) AS TO_EXTENSION_ID,
    TRIM(TO_LOCATION) AS TO_LOCATION,
    TRIM(TO_NAME) AS TO_NAME,
    TRIM(TO_DIALED_PHONE_NUMBER) AS TO_DIALED_PHONE_NUMBER,
    CAST(TRIM(EXTENSION_ID) AS BIGINT) AS EXTENSION_ID,
    'PUPS Pets Club' AS COMPANY,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
