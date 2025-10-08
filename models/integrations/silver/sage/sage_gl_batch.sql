{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'gl_batch',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_BATCH') }}
    {% if is_incremental() %}
    where cast(WHENMODIFIED as timestamp_ntz) > (
        select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    SELECT

    TRY_CAST(BATCHNO AS INT) AS BATCHNO,

    -- Core Identifiers
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRIM(BATCH_TITLE) AS BATCH_TITLE,
    
    CAST(BATCH_DATE AS DATE) AS BATCH_DATE,
    
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,
    
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
FROM source_data

)

select *
from cleaned
