
{% set company = var('company', 'spotless') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_department',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_DEPARTMENT_ID'
) }}

with source as (
    select
        RECORDNO AS DIM_DEPARTMENT_ID,
        TITLE AS DEPARTMENT_NAME,
        PARENTKEY AS PARENT,
        STATUS AS IS_INACTIVE,
        WHENMODIFIED AS LAST_MODIFIED_DATE
    from {{ ref('sage_department') }}
    
    WHERE (_FIVETRAN_DELETED = FALSE OR _FIVETRAN_DELETED IS NULL) 
    {% if is_incremental() %}
    AND WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source 