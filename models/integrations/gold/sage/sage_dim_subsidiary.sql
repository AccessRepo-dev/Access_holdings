
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_SUBSIDIARY_ID'
) }}

with source as (
    SELECT 
        LE.RECORDNO  AS DIM_SUBSIDIARY_ID,
        LE.LOCATIONID AS SUBSIDIARY_NAME,
        LE.NAME AS SUBSIDIARY_FULL_NAME,
        CAST(NULL AS NUMBER) AS CURRENCY_ID,
        CASE WHEN lower(LE.STATUS)='active' THEN FALSE ELSE TRUE END AS IS_INACTIVE,
        l.PARENTID AS PARENT_ID,
        LE.WHENMODIFIED AS LAST_MODIFIED_DATE

    FROM {{ get_silver_source(company, 'sage_location_entity') }} AS LE
    LEFT JOIN {{ get_silver_source(company, 'sage_location') }} AS L ON LE.LOCATIONID=L.ENTITY
    
    {% if is_incremental() %}
    and WHENMODIFIED > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }}
    )
    {% endif %}
)
SELECT *
FROM source