{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'EMPLOYEE_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'EMPLOYEE') }}
    {% if is_incremental() %}
    where LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(ID AS INT) AS EMPLOYEE_ID,
        TRIM(ENTITYID) AS ENTITY_ID,
        ACCOUNTNUMBER AS ACCOUNT_NUMBER,
        TRIM(EMPLOYEETYPE) AS EMPLOYEE_TYPE_ID,
        TRIM(TITLE) AS TITLE,
        TRIM(EMAIL) AS EMAIL,
        TRIM(JOBDESCRIPTION) AS JOB_DESCRIPTION,
        TRY_CAST(CLASS AS INT) AS CLASS_ID,
        TRY_CAST(DEPARTMENT AS INT) AS DEPARTMENT_ID,
        TRY_CAST(LOCATION AS INT) AS LOCATION_ID,
        TRY_CAST(CURRENCY AS INT) AS CURRENCY_ID,
        TRY_CAST(SUBSIDIARY AS INT) AS SUBSIDIARY_ID,
        CAST(DATECREATED AS DATE) AS DATE_CREATED,
        CAST(
            CASE 
                WHEN ISINACTIVE = 'T' THEN TRUE
                WHEN ISINACTIVE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS IS_INACTIVE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned