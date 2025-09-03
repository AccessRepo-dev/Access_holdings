{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'CATEGORY_NAME'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_COA_CAT_MEMBER') }}
    
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
        trim(CATEGORYNAME) as CATEGORY_NAME,

        -- Core Identifiers
        try_cast(RECORDNO as int) as RECORD_NO,
        try_cast(PARENTKEY as int) as PARENT_KEY,
        try_cast(SORTORD as int) as SORT_ORDER,
        trim(RECORD_URL) as RECORD_URL,

        -- Audit
        try_cast(CREATEDBY as int) as CREATED_BY,
        try_cast(MODIFIEDBY as int) as MODIFIED_BY,
        cast(WHENCREATED as timestamp_ntz) as CREATED_DATE,
        cast(WHENMODIFIED as timestamp_ntz) as WHEN_MODIFIED,

        -- Silver Load Metadata
        current_timestamp()::timestamp_ntz as SILVER_LOAD_DATE

    from source_data

)

select *
from cleaned
