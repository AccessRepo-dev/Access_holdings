{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'vendor',
    incremental_strategy = 'merge',
    unique_key = 'VENDORID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'VENDOR') }}
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
    UPPER(TRIM(VENDORID)) AS VENDORID,
    TRIM(ENTITY) AS ENTITY_ID,
    -- Core Identifiers
    TRIM(NAME) AS NAME,
    --CAST(NULL AS VARCHAR) AS PARENT_CLASS,
    CASE WHEN STATUS = 'active' THEN False 
    ELSE True
    END AS STATUS,
    {% if company == 'spotless'%}
        PARENTKEY,
    {% else %}
        CAST(NULL AS INTEGER) AS PARENTKEY,
    {% endif%}
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRIM(ISINDIVIDUAL) AS  IS_PERSON,

    -- Dates
    CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHENCREATED,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,
    TRIM(PARENTID) AS PARENTID,

    -- Flags / Deletes
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,

    -- Audit
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
FROM source_data

)

select *
from cleaned
