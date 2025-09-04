{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

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

   SELECT
    -- Primary Key
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,

    -- Core Info
    TRIM(NAME) AS NAME,
    TRIM(STATUS) AS STATUS,
    TRY_CAST(DATETYPE AS FLOAT) AS DATETYPE,
    CAST(BUDGETING AS BOOLEAN) AS BUDGETING,

    -- Headers
    TRIM(HEADER_1) AS HEADER_1,
    TRIM(HEADER_2) AS HEADER_2,

    -- Dates
    CAST(START_DATE AS DATE) AS START_DATE,
    CAST(END_DATE AS DATE) AS END_DATE,
    CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHENCREATED,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Fivetran
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    
    -- Silver Load Metadata
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM source_data


)

select *
from cleaned
