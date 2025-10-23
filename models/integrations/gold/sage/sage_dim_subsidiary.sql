
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
        LE.NAME AS SUBSIDIARY_NAME,
        CASE WHEN LE.PARENTNAME IS NULL OR LE.PARENTNAME = '' THEN LE.NAME ELSE CONCAT(LE.PARENTNAME,' : ',LE.NAME) END AS SUBSIDIARY_FULL_NAME,
        LE.PARENTNAME AS PARENT_NAME,
        LE.NAME AS CHILD_NAME,
        CAST(NULL AS NUMBER) AS CURRENCY_ID,
        STATUS AS IS_INACTIVE,
        PARENTKEY AS PARENT_ID,
        LE.WHENMODIFIED AS LAST_MODIFIED_DATE

    FROM {{ get_silver_source(company, 'LOCATION') }} AS LE
    
    {% if is_incremental() %}
    WHERE WHENMODIFIED > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }}
    )
    {% endif %}
)
SELECT *
FROM source