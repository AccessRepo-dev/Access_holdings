{% set company = var('company', 'wagway') | lower %}
{% set sourcesystem  = var('sourcesystem', 'netsuite') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'ENTITY') }}
    {% if is_incremental() %}
    where 
        cast(LASTMODIFIEDDATE as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(ID AS INT) AS ID,
        TRIM(ENTITYID) AS ENTITYID,
        TRY_CAST(ENTITYNUMBER AS INT) AS ENTITYNUMBER,
        TRIM("TYPE") AS "TYPE",
        TRIM(ENTITYTITLE) AS ENTITYTITLE,
        TRIM(FIRSTNAME) AS FIRSTNAME,
        TRIM(LASTNAME) AS LASTNAME,
        TRIM(EMAIL) AS EMAIL,
        TRY_CAST(CUSTOMER AS INT) AS CUSTOMER,
        TRY_CAST(VENDOR AS INT) AS VENDOR,
        TRY_CAST(EMPLOYEE AS INT) AS EMPLOYEE,
        TRY_CAST(CONTACT AS INT) AS CONTACT,
        TRY_CAST("GROUP" AS INT) AS "GROUP",
        TRY_CAST(PARENT AS INT) AS PARENT,
        CAST(
            CASE 
                WHEN ISPERSON = 'T' THEN TRUE
                WHEN ISPERSON = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS ISPERSON,
        CAST(
            CASE 
                WHEN ISINACTIVE = 'T' THEN TRUE
                WHEN ISINACTIVE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS ISINACTIVE,
        CAST(DATECREATED AS DATE) AS DATECREATED,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LASTMODIFIEDDATE,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned