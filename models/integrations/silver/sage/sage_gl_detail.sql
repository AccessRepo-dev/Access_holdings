{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem', 'sage') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage' and var('company', 'amh') in ['amh']) }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_DETAIL') }}
    {% if is_incremental() %}
    where 
        cast(WHENMODIFIED as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    {% endif %}
),

cleaned as (
    select
        TRIM(RECORDNO) AS RECORDNO,
        CAST(BATCHKEY AS INT) AS BATCHKEY,
        CAST(BATCH_DATE AS DATE) AS BATCH_DATE,
        CAST(GLENTRYKEY AS INT) AS GLENTRYKEY,
        TRIM(SYMBOL) AS SYMBOL,
        CAST(LINE_NO AS INT) AS LINE_NO,
        CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select *
from cleaned
