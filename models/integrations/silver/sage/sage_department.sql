{% set company = var('company', 'spotless') | lower %}
{% set sourcesystem = var('sourcesystem', 'sage') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage' and var('company', 'spotless') in ['spotless','amh']) }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'DEPARTMENT') }}
    {% if is_incremental() %}
    where 
        cast(WHENMODIFIED as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    SELECT
    -- Primary Key
    UPPER(TRIM(DEPARTMENTID)) AS DEPARTMENTID,

    -- Core Identifiers
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRIM(TITLE) AS TITLE,
    CASE 
        WHEN lower(STATUS)='active' THEN FALSE
        ELSE TRUE 
    END  AS STATUS,

    -- Hierarchy
    TRIM(PARENTID) AS PARENTID,
    TRY_CAST(PARENTKEY AS INT) AS PARENTKEY,

    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Flags / Deletes
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,

    -- Audit
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
FROM source_data

)

select *
from cleaned
