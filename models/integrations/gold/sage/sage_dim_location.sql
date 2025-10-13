
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_location',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_LOCATION_ID'
) }}

with source as (
    SELECT 
        l.RECORDNO AS DIM_LOCATION_ID,
        l.NAME AS LOCATION_NAME,
        l.PARENTKEY AS PARENT,
        l.PARENTNAME AS PARENT_NAME,
        le.RECORDNO AS SUBSIDIARY_ID,
        l.STATUS AS IS_INACTIVE,
        l.WHENMODIFIED AS LAST_MODIFIED_DATE

    FROM {{ get_silver_source(company, 'LOCATION') }} l
    LEFT JOIN {{ get_silver_source(company, 'LOCATION_ENTITY') }} le ON l.ENTITY = le.LOCATIONID 
    
    {% if is_incremental() %}
    where l.WHENMODIFIED > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }}
    )
    {% endif %}
)
SELECT *
FROM source