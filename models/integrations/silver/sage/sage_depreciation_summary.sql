{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DEPRECIATION_SUMMARY_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'DEPRECIATION_SUMMARY') }}
    {% if is_incremental() %}
    where CAST(UPDATED_AT AS TIMESTAMP_NTZ) > (
        select coalesce(max(UPDATED_AT), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(ID AS INT) AS DEPRECIATION_SUMMARY_ID,
        TRY_CAST(AMOUNT AS FLOAT) AS AMOUNT,
        TRY_CAST(NAME AS INT) AS NAME,

        COALESCE(
            TRY_TO_DATE(GL_POSTING_DATE, 'MM/DD/YYYY'),
            TRY_TO_DATE(GL_POSTING_DATE, 'YYYY-MM-DD'),
            TRY_TO_DATE(GL_POSTING_DATE, 'MM-DD-YY')
        ) AS GL_POSTING_DATE,

        TRY_CAST(CREATED_AT AS TIMESTAMP_NTZ) AS CREATED_AT,
        TRY_CAST(UPDATED_AT AS TIMESTAMP_NTZ) AS UPDATED_AT,

        -- Split RDEPARTMENT
        TRY_CAST(REGEXP_SUBSTR(DIMENSIONS, 'RDEPARTMENT: ([0-9]+)--', 1, 1, 'e', 1) AS INT) AS RDEPARTMENT_ID,
        TRIM(REGEXP_SUBSTR(DIMENSIONS, 'RDEPARTMENT: [0-9]+--([^,]+)', 1, 1, 'e', 1)) AS RDEPARTMENT_NAME,

        -- Split RLOCATION
        TRY_CAST(REGEXP_SUBSTR(DIMENSIONS, 'RLOCATION: ([0-9]+)--', 1, 1, 'e', 1) AS INT) AS RLOCATION_ID,
        TRIM(REGEXP_SUBSTR(DIMENSIONS, 'RLOCATION: [0-9]+--([^,]+)', 1, 1, 'e', 1)) AS RLOCATION_NAME,

        -- Split RREVENUE_CENTER
        TRY_CAST(REGEXP_SUBSTR(DIMENSIONS, 'Rrevenue_center: ([0-9]+)--', 1, 1, 'e', 1) AS INT) AS RREVENUE_CENTER_ID,
        TRIM(REGEXP_SUBSTR(DIMENSIONS, 'Rrevenue_center: [0-9]+--([^,]+)', 1, 1, 'e', 1)) AS RREVENUE_CENTER_NAME,

        -- Split RVENDOR
        TRY_CAST(REGEXP_SUBSTR(DIMENSIONS, 'RVENDOR: ([0-9]+)--', 1, 1, 'e', 1) AS INT) AS RVENDOR_ID,
        TRIM(REGEXP_SUBSTR(DIMENSIONS, 'RVENDOR: [0-9]+--([^,]+)', 1, 1, 'e', 1)) AS RVENDOR_NAME,

        -- Split RCLASS
        TRY_CAST(REGEXP_SUBSTR(DIMENSIONS, 'RCLASS: ([0-9]+)--', 1, 1, 'e', 1) AS INT) AS RCLASS_ID,
        TRIM(REGEXP_SUBSTR(DIMENSIONS, 'RCLASS: [0-9]+--([^,]+)', 1, 1, 'e', 1)) AS RCLASS_NAME,

        -- Flags / Deletes
        _FIVETRAN_DELETED AS IS_DELETED,

        -- Audit
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

    from source_data
)

select *
from cleaned
