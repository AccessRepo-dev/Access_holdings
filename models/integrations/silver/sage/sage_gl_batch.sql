{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'BATCH_NO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_BATCH') }}
    {% if is_incremental() %}
    where cast(WHENMODIFIED as timestamp_ntz) > (
        select coalesce(max(WHEN_MODIFIED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select

        -- Primary Key
        try_cast(BATCHNO as int) as BATCH_NO,

        -- Core Identifiers
        try_cast(RECORDNO as int) as RECORD_NO,
        trim(BATCH_TITLE) as BATCH_TITLE,
        try_cast(BASELOCATION as int) as BASE_LOCATION,
        trim(BASELOCATION_NO) as BASE_LOCATION_NO,
        trim(JOURNAL) as JOURNAL,
        trim(MODULE) as MODULE,
        trim(STATE) as STATE,
        trim(TAXIMPLICATIONS) as TAX_IMPLICATIONS,
        trim(TRANSACTIONSOURCE) as TRANSACTION_SOURCE,

        -- Entity Info
        trim(MEGAENTITYID) as MEGA_ENTITY_ID,
        try_cast(MEGAENTITYKEY as int) as MEGA_ENTITY_KEY,
        trim(MEGAENTITYNAME) as MEGA_ENTITY_NAME,

        -- References
        trim(REFERENCENO) as REFERENCE_NO,
        trim(RECORD_URL) as RECORD_URL,
        try_cast(PRBATCHKEY as int) as PR_BATCH_KEY,
        try_cast(REVERSEDKEY as int) as REVERSED_KEY,
        try_cast(RFIXED_ASSETS_LOG as int) as R_FIXED_ASSETS_LOG,
        try_cast(RDEPRECIATION_SCHEDULE as int) as R_DEPRECIATION_SCHEDULE,
        try_cast(RPESENTRY as int) as R_PES_ENTRY,
        try_cast(SCHOPKEY as int) as SCHOP_KEY,
        try_cast(SUPDOCKEY as int) as SUPDOC_KEY,
        trim(SUPDOCID) as SUPDOC_ID,
        try_cast(USERKEY as int) as USER_KEY,
        trim(USERINFO_LOGINID) as USERINFO_LOGIN_ID,

        -- Flags
        cast(STATISTICAL as boolean) as IS_STATISTICAL,

        -- Dates
        cast(BATCH_DATE as date) as BATCH_DATE,
        cast(REVERSED as date) as REVERSED_DATE,
        cast(REVERSEDFROM as date) as REVERSED_FROM_DATE,

        -- Audit
        try_cast(CREATEDBY as int) as CREATED_BY,
        trim(CREATEDBYLOGINID) as CREATED_BY_LOGIN_ID,
        try_cast(MODIFIEDBY as int) as MODIFIED_BY,
        trim(MODIFIEDBYID) as MODIFIED_BY_ID,
        trim(MODIFIEDBYLOGINID) as MODIFIED_BY_LOGIN_ID,
        cast(WHENCREATED as timestamp_ntz) as CREATED_DATE,
        cast(WHENMODIFIED as timestamp_ntz) as WHEN_MODIFIED,
        cast(MODIFIED as timestamp_ntz) as MODIFIED_DATE,

        _FIVETRAN_DELETED as IS_DELETED,
        current_timestamp()::timestamp_ntz as SILVER_LOAD_DATE

    from source_data
)

select *
from cleaned
