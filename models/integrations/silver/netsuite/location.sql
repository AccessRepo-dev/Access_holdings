{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'LOCATION_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'LOCATION') }}
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
        TRY_CAST(ID AS INT) AS LOCATION_ID,
        TRIM(NAME) AS LOCATION_NAME,
        TRIM(FULLNAME) AS LOCATION_FULL_NAME,
        TRIM(LOCATIONTYPE) AS LOCATION_TYPE,
        TRY_CAST(PARENT AS INT) AS PARENT_ID,
        TRY_CAST(SUBSIDIARY AS INT) AS SUBSIDIARY_ID,
        LATITUDE AS LATITUDE,
        LONGITUDE AS LONGITUDE,
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