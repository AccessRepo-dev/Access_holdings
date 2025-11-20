{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'location_entity',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'LOCATION_ENTITY') }}

    {% if is_incremental() %}
    where 
        cast(WHENMODIFIED as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    {% endif %}

),

cleaned as (

    SELECT
    -- Primary Key
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,

    -- Core Identifiers
    TRIM(LOCATIONID) AS LOCATIONID,
    TRIM(NAME) AS NAME ,
    TRIM(ENTITY) AS ENTITY,
    {%if company | lower == 'amh'%}
    TRIM(DIVISION_MAPPING) AS DIVISION_MAPPING,
    {%else%}
    CAST(NULL AS VARCHAR) AS DIVISION_MAPPING,
    {%endif%}
    CASE WHEN STATUS ='active' THEN FALSE 
        WHEN STATUS = 'incative' THEN TRUE
        ELSE NULL 
    END AS STATUS,

    -- Accounting & Legal
    TRIM(FEDERALID) AS FEDERALID,
   

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
