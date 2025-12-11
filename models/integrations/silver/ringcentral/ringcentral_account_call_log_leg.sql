{% set company = var('company', 'wagway') | lower %}
{% set sourcesystem  = var('sourcesystem', 'ringcentral') | lower %}

{{ config(enabled =(var('sourcesystem','ringcentral')| lower) =='ringcentral') }}

{{ config(
    database=get_target_database(var('company','wagway')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ACCOUNT_CALL_LOG_ID'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'ACCOUNT_CALL_LOG_LEG') }}

    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select dateadd(
            day, 
            -1,
            coalesce(max(t._FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        )
        from {{ this }} t
    )
    {% endif %}

)
,

cleaned as 
(
    select
    TRIM(ACCOUNT_CALL_LOG_ID) AS ACCOUNT_CALL_LOG_ID,
    CAST(INDEX AS INT) AS INDEX,
    CAST(START_TIME AS TIMESTAMP_NTZ) AS START_TIME,
    CAST(DURATION AS INT) AS DURATION,
    CAST(DURATION_MS AS INT) AS DURATION_MS,
    TRIM(TYPE) AS TYPE,
    TRIM(INTERNAL_TYPE) AS INTERNAL_TYPE,
    TRIM(DIRECTION) AS DIRECTION,
    TRIM(ACTION) AS ACTION,
    TRIM(RESULT) AS RESULT,
    TRIM(REASON) AS REASON,
    TRIM(REASON_DESCRIPTION) AS REASON_DESCRIPTION,
    TRIM(FROM_PHONE_NUMBER) AS FROM_PHONE_NUMBER,
    CAST(FROM_EXTENSION_NUMBER AS INT) AS FROM_EXTENSION_NUMBER,
    CAST(FROM_EXTENSION_ID AS BIGINT) AS FROM_EXTENSION_ID,
    TRIM(FROM_LOCATION) AS FROM_LOCATION,
    TRIM(FROM_NAME) AS FROM_NAME,
    TRIM(FROM_DIALED_PHONE_NUMBER) AS FROM_DIALED_PHONE_NUMBER,
    TRIM(TO_PHONE_NUMBER) AS TO_PHONE_NUMBER,
    CAST(TO_EXTENSION_NUMBER AS INT) AS TO_EXTENSION_NUMBER,
    CAST(TO_EXTENSION_ID AS BIGINT) AS TO_EXTENSION_ID,
    TRIM(TO_LOCATION) AS TO_LOCATION,
    TRIM(TO_NAME) AS TO_NAME,
    TRIM(TO_DIALED_PHONE_NUMBER) AS TO_DIALED_PHONE_NUMBER,
    CAST(EXTENSION_ID AS BIGINT) AS EXTENSION_ID,
    'PUPS Pets Club' AS COMPANY,
    CAST(_FIVETRAN_SYNCED AS TIMESTAMP_NTZ) AS _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select * from cleaned
