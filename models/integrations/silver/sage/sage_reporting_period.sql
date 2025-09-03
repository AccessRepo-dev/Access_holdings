{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'REPORTING_PERIOD_ID'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'REPORTING_PERIOD') }}
    
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
        try_cast(RECORDNO as int) as REPORTING_PERIOD_ID,

        -- Core Info
        trim(NAME) as REPORTING_PERIOD_NAME,
        trim(STATUS) as STATUS,
        try_cast(DATETYPE as float) as DATE_TYPE,
        cast(BUDGETING as boolean) as IS_BUDGETING,

        -- Headers
        trim(HEADER_1) as HEADER_1,
        trim(HEADER_2) as HEADER_2,

        -- Dates
        cast(START_DATE as date) as START_DATE,
        cast(END_DATE as date) as END_DATE,
        cast(WHENCREATED as timestamp_ntz) as WHEN_CREATED,
        cast(WHENMODIFIED as timestamp_ntz) as WHEN_MODIFIED,

        -- Fivetran
        _FIVETRAN_DELETED as IS_DELETED,
        
        -- Silver Load Metadata
        current_timestamp()::timestamp_ntz as SILVER_LOAD_DATE

    from source_data

)

select *
from cleaned
