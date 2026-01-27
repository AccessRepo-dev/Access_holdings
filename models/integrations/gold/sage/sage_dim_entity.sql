{% set company = var('company', 'spotless') | lower %}
{{ config(enabled = var('company', 'spotless') in ['spotless', 'amh'] ) }}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_entity',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_ENTITY_ID'
) }}

with source as (
    select
        RECORDNO AS DIM_ENTITY_ID,
        ENTITY_ID,
        NULL AS INTERNAL_ENTITY_ID,
        CAST(NULL AS NUMBER) AS ENTITY_NUMBER,
        NAME AS ENTITY_TITLE,
        NULL AS FIRST_NAME,
        NULL AS LAST_NAME,
        NULL AS ENTITY_TYPE,
      
        CAST(NULL AS NUMBER) AS CONTACT_ID,
        CAST(NULL AS NUMBER) EMPLOYEE_ID,
        CAST(NULL AS NUMBER) CUSTOMER_ID,
        NULL AS EMAIL,
        CAST(NULL AS NUMBER) GROUP_ID,
        PARENTID  AS PARENT_ID,
        STATUS AS IS_INACTIVE,
        IS_PERSON,
        WHENMODIFIED AS LAST_MODIFIED_DATE,
        WHENCREATED AS DATE_CREATED,
        VENDORID AS VENDOR_ID

    from {{ ref('sage_vendor') }}
    
    where  (_FIVETRAN_DELETED = FALSE OR _FIVETRAN_DELETED IS NULL )

    {% if is_incremental() %}
        and WHENMODIFIED > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}

)
select *
from source




       
   
        
       
        
