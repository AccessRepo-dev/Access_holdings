{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

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

    SELECT
    -- Primary Key
    TRIM(CATEGORYNAME) AS CATEGORYNAME,

    -- Core Identifiers
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRY_CAST(PARENTKEY AS INT) AS PARENTKEY,
    TRY_CAST(SORTORD AS INT) AS SORTORD,
    TRIM(RECORD_URL) AS RECORD_URL,

    -- Audit
    TRY_CAST(CREATEDBY AS INT) AS CREATEDBY,
    TRY_CAST(MODIFIEDBY AS INT) AS MODIFIEDBY,
    CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHENCREATED,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Silver Load Metadata
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
FROM source_data;


)

select *
from cleaned
