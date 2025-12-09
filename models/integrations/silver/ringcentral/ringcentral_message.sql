{% set company = var('company', 'wagway') | lower %}
{% set sourcesystem  = var('sourcesystem', 'ringcentral') | lower %}

{{ config(enabled =(var('sourcesystem','ringcentral')| lower) =='ringcentral') }}

{{ config(
    database=get_target_database(var('company','wagway')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with raw as 
(
    select *
    from {{ get_raw_source(company, sourcesystem, 'MESSAGE') }}

    {% if is_incremental() %}
        where LAST_MODIFIED_TIME > (
            select dateadd(
                day,
                -1,
                coalesce(max(t.LAST_MODIFIED_TIME), '1900-01-01'::timestamp_ntz)
            )
            from {{ this }} t
        )
    {% endif %}
),

cleaned as 
(
    select
        CAST(ID AS BIGINT) AS ID,
        TRIM(EXTENSION_ID) AS EXTENSION_ID,
        TRIM(AVAILABILITY) AS AVAILABILITY,
        TRIM(CONVERSATION_ID) AS CONVERSATION_ID,
        CAST(TRIM(CREATION_TIME) AS TIMESTAMP_TZ) AS CREATION_TIME,
        TRIM(DELIVERY_ERROR_CODE) AS DELIVERY_ERROR_CODE,
        TRIM(DIRECTION) AS DIRECTION,
        TRIM(FAX_PAGE_COUNT) AS FAX_PAGE_COUNT,
        TRIM(FAX_RESOLUTION) AS FAX_RESOLUTION,
        TRIM(MESSAGE_STATUS) AS MESSAGE_STATUS,
        CAST(TRIM(PG_TO_DEPARTMENT) AS BOOLEAN) AS PG_TO_DEPARTMENT,
        TRIM(PRIORITY) AS PRIORITY,
        TRIM(READ_STATUS) AS READ_STATUS,
        TRIM(SMS_DELIVERY_TIME) AS SMS_DELIVERY_TIME,
        CAST(TRIM(SMS_SENDING_ATTEMPTS_COUNT) AS INT) AS SMS_SENDING_ATTEMPTS_COUNT,
        TRIM(SUBJECT) AS SUBJECT,
        TRIM(TYPE) AS TYPE,
        TRIM(VM_TRANSCRIPTION_STATUS) AS VM_TRANSCRIPTION_STATUS,
        TRIM(COVER_INDEX) AS COVER_INDEX,
        TRIM(COVER_PAGE_TEXT) AS COVER_PAGE_TEXT,
        TRIM(FROM_EXTENSION_ID) AS FROM_EXTENSION_ID,
        TRIM(FROM_LOCATION) AS FROM_LOCATION,
        CAST(LAST_MODIFIED_TIME AS TIMESTAMP_NTZ) AS LAST_MODIFIED_TIME,
        CAST(TRIM(_FIVETRAN_SYNCED) AS TIMESTAMP_TZ) AS _FIVETRAN_SYNCED,

        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned