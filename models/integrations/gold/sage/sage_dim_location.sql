
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'LOCATION_ID'
) }}

with source as (
    SELECT 
        RECORDNO AS LOCATION_ID,
        NAME AS LOCATION_NAME,
        PARENTKEY AS PARENT,
        ABS(HASH(ENTITY)) AS SUBSIDIARY_ID,
        STATUS AS IS_INACTIVE,
        WHENMODIFIED AS LAST_MODIFIED_DATE

    FROM {{ get_silver_source(company, 'sage_location') }}
    
    {% if is_incremental() %}
    and WHENMODIFIED > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }}
    )
    {% endif %}
)
SELECT *
FROM source