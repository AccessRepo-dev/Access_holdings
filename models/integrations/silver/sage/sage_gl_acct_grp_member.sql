{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    unique_key = 'RECORDNO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_ACCT_GRP_MEMBER') }}
    {% if is_incremental() %}
    where cast(WHENMODIFIED as timestamp_ntz) > (
        select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
   
    {% endif %}
),

cleaned as (
    select
        -- Primary Key
        TRIM(RECORDNO) AS RECORDNO,

        -- Foreign Keys
        TRY_CAST(CHILDKEY AS INT) AS CHILDKEY,
        TRY_CAST(PARENTKEY AS INT) AS PARENTKEY,

        -- Core Identifiers
        TRIM(CHILDNAME) AS CHILDNAME,
        TRY_CAST(CREATEDBY AS INT) AS CREATEDBY,
        TRY_CAST(MODIFIEDBY AS INT) AS MODIFIEDBY,
        TRIM(NAME) AS NAME,
        TRIM(RECORD_URL) AS RECORD_URL,
        TRY_CAST(SORTORD AS INT) AS SORTORD,
        CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHENCREATED,
        CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

        -- Audit
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

    from source_data
)
select *
from cleaned



