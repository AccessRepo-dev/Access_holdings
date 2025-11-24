{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') | lower == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_entity',
    incremental_strategy = 'merge',
    unique_key = 'DIM_ENTITY_ID'
) }}

with source as (
    select
        ID AS DIM_ENTITY_ID,
        ENTITYID AS ENTITY_ID,
        ENTITYNUMBER AS ENTITY_NUMBER,
        ENTITYTITLE AS ENTITY_TITLE,
        FIRSTNAME AS FIRST_NAME,
        LASTNAME AS LAST_NAME,
        TYPE AS ENTITY_TYPE,
        ISPERSON AS IS_PERSON,
        CONTACT AS CONTACT_ID,
        EMPLOYEE AS EMPLOYEE_ID,
        CUSTOMER AS CUSTOMER_ID,
        DATECREATED AS DATE_CREATED,
        EMAIL AS EMAIL,
        "GROUP" AS GROUP_ID,
        ISINACTIVE AS IS_INACTIVE,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,
        PARENT AS PARENT_ID,
        VENDOR AS VENDOR_ID
    from {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_ENTITY') }}
    where (_fivetran_deleted is null or _fivetran_deleted = false)
    {% if is_incremental() %}
    and LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source