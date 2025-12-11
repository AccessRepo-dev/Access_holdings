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
    from {{ get_raw_source(company, sourcesystem, 'GL_BUDGET_ITEM') }}
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
        ACCT_NO,
        COALESCE(ACCOUNTKEY,0) AS ACCOUNTKEY,
        AMOUNT,
        BUDGETKEY,
        COALESCE(CLASSDIMKEY,0) AS CLASSDIMKEY,
        COALESCE(DEPTKEY,0) AS DEPTKEY,
        COALESCE(LOCATIONKEY,0) AS LOCATIONKEY,
        PERIODKEY,
        PSTARTDATE,
        COALESCE(PROJECTDIMKEY,0) AS PROJECTDIMKEY,
        CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,
        NORMALBALANCE,
        _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select *
from cleaned
