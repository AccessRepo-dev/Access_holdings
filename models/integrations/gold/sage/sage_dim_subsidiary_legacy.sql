
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
        RECORDNO AS DIM_SUBSIDIARY_ID,
        LOCATIONID AS SUBSIDIARY_ID,
        ENTITY AS SUBSIDIARY_TITLE,
        FEDERALID AS SUBSIDIARY_NUMBER,
        STATUS AS IS_INACTIVE,
        WHENCREATED AS DATE_CREATED,
        WHENMODIFIED AS LAST_MODIFIED_DATE



    FROM {{ get_silver_source(company, 'sage_location_entity') }}
    
    {% if is_incremental() %}
    and WHENMODIFIED > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }}
    )
    {% endif %}
)
SELECT *
FROM source