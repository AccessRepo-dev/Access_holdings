{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_class',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CLASS_ID'
) }}

with source as (
    select
        RECORDNO AS DIM_CLASS_ID,
        cast(NULL AS INT) AS CLASS_ID,
        NAME AS NAME,
        null AS FULLNAME,
        PARENT_CLASS,
        PARENTKEY AS PARENT_ID,
        STATUS AS IS_INACTIVE,
        WHENMODIFIED AS LAST_MODIFIED_DATE
    from {{ get_silver_source(company, 'CLASS') }}
    
    {% if is_incremental() %}
    where WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source
