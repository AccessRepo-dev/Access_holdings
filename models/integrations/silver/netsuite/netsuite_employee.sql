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
    from {{ get_raw_source(company, sourcesystem, 'EMPLOYEE') }}
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
        ACCOUNTNUMBER AS ACCOUNTNUMBER,
        TRIM(EMPLOYEETYPE) AS EMPLOYEETYPE,
        TRIM(TITLE) AS TITLE,
        TRIM(EMAIL) AS EMAIL,
        TRIM(JOBDESCRIPTION) AS JOBDESCRIPTION,
        TRY_CAST(CLASS AS INT) AS CLASS,
        TRY_CAST(DEPARTMENT AS INT) AS DEPARTMENT,
        TRY_CAST(LOCATION AS INT) AS LOCATION,
        TRY_CAST(CURRENCY AS INT) AS CURRENCY,
        TRY_CAST(SUBSIDIARY AS INT) AS SUBSIDIARY,
        CAST(DATECREATED AS DATE) AS DATECREATED,
        CAST(
            CASE 
                WHEN ISINACTIVE = 'T' THEN TRUE
                WHEN ISINACTIVE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS ISINACTIVE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LASTMODIFIEDDATE,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned