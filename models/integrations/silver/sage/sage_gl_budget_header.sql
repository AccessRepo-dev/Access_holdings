{% set company = var('company', 'spotless') | lower %}
{% set sourcesystem = var('sourcesystem', 'sage') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}
{{ config(enabled = var('company', 'spotless') in ['spotless','amh']) }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_BUDGET_HEADER') }}
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
        RECORDNO,
        TRIM(BUDGETID) AS BUDGETID,
        TRIM(DESCRIPTION) AS DESCRIPTION,
        CASE STATUS
            WHEN 'active' THEN FALSE 
            WHEN 'inactive' THEN TRUE 
            ELSE NULL 
        END AS STATUS,
        CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,
        _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select *
from cleaned
