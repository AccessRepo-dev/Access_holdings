{% set company = var('company', 'spotless') | lower %}
{{ config(enabled = var('company', 'spotless') in ['spotless', 'amh'] ) }}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}

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
        RECORDNO AS CLASS_ID,
        CLASSID AS NAME,
        NAME AS FULLNAME,
        PARENT_CLASS,
        PARENTKEY AS PARENT_ID,
        STATUS AS IS_INACTIVE,
        WHENMODIFIED AS LAST_MODIFIED_DATE
    from {{ref('sage_class')}}
    
    where (_FIVETRAN_DELETED = FALSE OR _FIVETRAN_DELETED IS NULL) 

    {% if is_incremental() %}
        and WHENMODIFIED > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}

    {% if company == 'spotless' %}
        and PARENTKEY IN (18,28)
        and STATUS = False
    {% endif %}
)
select *
from source
