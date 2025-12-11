{% set company = var('company', 'spotless') | lower %}
{{ config(enabled = var('company', 'spotless') in ['spotless', 'amh'] ) }}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_subsidiary',
    materialized = 'table',
    unique_key = 'DIM_SUBSIDIARY_ID'
) }}

with source as (
    SELECT 
        L.RECORDNO  AS DIM_SUBSIDIARY_ID,
        L.NAME AS SUBSIDIARY_NAME,
        CASE WHEN L.PARENTNAME IS NULL OR L.PARENTNAME = '' THEN L.NAME ELSE CONCAT(L.PARENTNAME,' : ',L.NAME) END AS SUBSIDIARY_FULL_NAME,
        L.PARENTNAME AS PARENT_NAME,
        L.NAME AS CHILD_NAME,
        CAST(NULL AS NUMBER) AS CURRENCY_ID,
        LE.DIVISION_MAPPING,
        L.STATUS AS IS_INACTIVE,
        L.PARENTKEY AS PARENT_ID,
        L.WHENMODIFIED AS LAST_MODIFIED_DATE
       
    FROM {{ ref('sage_location') }} AS L
    LEFT JOIN {{ ref('sage_location_entity') }} AS LE ON L.LOCATIONID = LE.LOCATIONID
    WHERE  (L._FIVETRAN_DELETED  IS NULL OR  L._FIVETRAN_DELETED  = FALSE)
)
SELECT *
FROM source