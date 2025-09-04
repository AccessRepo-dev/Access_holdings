{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source as (
    select
        ACCOUNTNUMBER AS ACCOUNT_NUMBER,
        CLASS AS CLASS_ID,
        DATECREATED AS DATE_CREATED,
        CURRENCY AS CURRENCY,
        DEPARTMENT AS DEPATMENT_ID,
        EMAIL AS EMAIL,
        ID AS EMPLOYEE_ID,
        EMPLOYEETYPE AS EMPLOYEE_TYPE_ID,
        ENTITYID AS ENTITY_ID,
        ISINACTIVE AS IS_INACTIVE,
        JOBDESCRIPTION AS JOB_DESCRIPTION,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,
        LOCATION AS LOCATION_ID,
        NULL AS EMPLOYEE_STATUS_ID,
        SUBSIDIARY AS SUBSIDIARY,
        TITLE AS TITLE
    from {{ get_raw_source(company, sourcesystem, 'netsuite_employee') }}
    where (_fivetran_deleted is null or _fivetran_deleted = false)
      and (IS_DELETED is null or IS_DELETED = false)
)
select *
from source

{% if is_incremental() %}
where EMPLOYEE_ID not in (select EMPLOYEE_ID from {{ this }})
{% endif %}