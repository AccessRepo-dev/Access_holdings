
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_subsidiary',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_SUBSIDIARY_ID'
) }}

with source as (
    SELECT 
        LE.RECORDNO  AS DIM_SUBSIDIARY_ID,
        LE.LOCATIONID AS SUBSIDIARY_NAME,
        LE.NAME AS SUBSIDIARY_FULL_NAME,
        NULL AS SUB_NAME2,
        NULL AS SUB_NAME3,
        NULL AS SUB_NAME4,
        NULL AS SUB_NAME5,
        NULL AS SUB_NAME6,
        CAST(NULL AS NUMBER) AS CURRENCY_ID,
        STATUS AS IS_INACTIVE,
        NULL AS PARENT_ID,
        LE.WHENMODIFIED AS LAST_MODIFIED_DATE

    FROM {{ get_silver_source(company, 'LOCATION_ENTITY') }} AS LE
    
    {% if is_incremental() %}
    WHERE WHENMODIFIED > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }}
    )
    {% endif %}
)
SELECT *
FROM source