{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'employee',
    incremental_strategy = 'merge',
    unique_key = 'EMPLOYEEID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'EMPLOYEE') }}
    {% if is_incremental() %}
    where CAST(WHENMODIFIED AS TIMESTAMP_NTZ) > (
        select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    SELECT
    -- Primary Key
    TRIM(EMPLOYEEID) AS EMPLOYEEID,

    -- Core Identifiers
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    CASE WHEN LOWER(STATUS)='active' THEN FALSE ELSE TRUE END AS STATUS,
    TRIM(TITLE) AS TITLE,

    TRIM(PERSONALINFO_EMAIL_1) AS PERSONALINFO_EMAIL_1,

    -- Department
    TRIM(DEPARTMENTID) AS DEPARTMENTID,
    TRY_CAST(DEPARTMENTKEY AS INT) AS DEPARTMENTKEY,

    -- Location
    TRIM(LOCATIONID) AS LOCATIONID,
    TRY_CAST(LOCATIONKEY AS INT) AS LOCATIONKEY,

    -- Employee Type
    TRY_CAST(EMPTYPEKEY AS INT) AS EMPTYPEKEY,

    -- Entity
    TRIM(ENTITY) AS ENTITY,
     {% if company == 'spotless' and sourcesystem == 'sage' %}
        TRIM(MEGAENTITYID) AS MEGAENTITYID,
        TRY_CAST(MEGAENTITYKEY AS INT) AS MEGAENTITYKEY,
    {% else %}
        null AS MEGAENTITYID,
        null AS MEGAENTITYKEY,
    {% endif%}
    
    -- Dates
    CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHENCREATED,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Audit
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
FROM source_data

)

select *
from cleaned
