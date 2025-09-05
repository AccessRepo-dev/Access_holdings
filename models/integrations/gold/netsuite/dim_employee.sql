{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'EMPLOYEE_ID'
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
    from {{ get_silver_source(company, 'netsuite_employee') }}
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