{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'LOCATIONID'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'LOCATION') }}
    
    {% if is_incremental() %}
        where WHENMODIFIED > (
            select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
            from {{ this }}
        )
        or _FIVETRAN_DELETED = true
    {% endif %}

),

cleaned as (

    SELECT
    -- Primary Key
    TRIM(LOCATIONID) AS LOCATIONID,
    -- Core Identifiers
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRIM(NAME) AS NAME,
    TRIM(ENTITY) AS ENTITY,
    CASE WHEN LOWER(STATUS)='active' THEN FALSE ELSE TRUE END AS STATUS,
    TRIM(LOCATIONTYPE) AS LOCATIONTYPE,
   
    -- Dates
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Misc
    TRIM(ADDRESSCOUNTRYDEFAULT) AS ADDRESSCOUNTRYDEFAULT,

    -- Relationships

     {% if company == 'spotless' and sourcesystem == 'sage' %}
        TRIM(PARENTID) AS PARENTID,
        TRIM(PARENTNAME) AS PARENTNAME,
        TRY_CAST(PARENTKEY AS INT) AS PARENTKEY,
    {% else %}
        null as PARENTID,
        null AS PARENTNAME,
        null AS PARENTKEY,
    {% endif%}
   
    
    -- Audit
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM source_data

)

select * from cleaned
