{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'INTERNAL_ENTITY_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'ENTITY') }}
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
        TRY_CAST(ID AS INT) AS INTERNAL_ENTITY_ID,
        TRIM(ENTITYID) AS ENTITY_ID,
        TRY_CAST(ENTITYNUMBER AS INT) AS ENTITY_NUMBER,
        TRIM("TYPE") AS ENTITY_TYPE,
        TRIM(ENTITYTITLE) AS ENTITY_TITLE,
        TRIM(FIRSTNAME) AS FIRST_NAME,
        TRIM(LASTNAME) AS LAST_NAME,
        TRIM(EMAIL) AS EMAIL,
        TRY_CAST(CUSTOMER AS INT) AS CUSTOMER_ID,
        TRY_CAST(VENDOR AS INT) AS VENDOR_ID,
        TRY_CAST(EMPLOYEE AS INT) AS EMPLOYEE_ID,
        TRY_CAST(CONTACT AS INT) AS CONTACT_ID,
        TRY_CAST("GROUP" AS INT) AS GROUP_ID,
        TRY_CAST(PARENT AS INT) AS PARENT_ID,
        CAST(
            CASE 
                WHEN ISPERSON = 'T' THEN TRUE
                WHEN ISPERSON = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS IS_PERSON,
        CAST(
            CASE 
                WHEN ISINACTIVE = 'T' THEN TRUE
                WHEN ISINACTIVE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS IS_INACTIVE,
        CAST(DATECREATED AS DATE) AS DATE_CREATED,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned