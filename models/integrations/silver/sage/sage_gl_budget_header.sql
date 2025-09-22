{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'gl_budget_header',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_BUDGET_HEADER') }}
    {% if is_incremental() %}
    where cast(WHENMODIFIED as timestamp_ntz) > (
        select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
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
        WHENMODIFIED,
        _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select *
from cleaned
