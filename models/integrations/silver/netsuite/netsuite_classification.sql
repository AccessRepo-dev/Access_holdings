{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'CLASS_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'CLASSIFICATION') }}
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
        TRY_CAST(ID AS INT) AS CLASS_ID,
        TRY_CAST(EXTERNALID AS INT) AS EXTERNAL_ID,
        TRIM(NAME) AS CLASS_NAME,
        TRIM(FULLNAME) AS CLASS_FULL_NAME,
        TRY_CAST(PARENT AS INT) AS PARENT_ID,
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
