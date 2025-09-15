
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table'
) }}

with source as (
    SELECT 
        ABS(HASH(LE.LOCATIONID))  AS SUBSIDIARY_ID,
        LE.LOCATIONID AS SUBSIDIARY_NAME,
        LE.NAME AS SUBSIDIARY_FULL_NAME,
        CAST(NULL AS NUMBER) AS CURRENCY_ID,
        CASE WHEN lower(LE.STATUS)='active' THEN FALSE ELSE TRUE END AS IS_INACTIVE,
        ABS(HASH(L.PARENTID)) AS PARENT_ID,
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