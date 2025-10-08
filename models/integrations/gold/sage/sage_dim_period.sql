
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_period',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_PERIOD_ID'
) }}

with source as (
    SELECT 
        RECORDNO AS DIM_PERIOD_ID,
        NAME AS PERIOD_NAME,
        START_DATE ,
        END_DATE ,
        NULL AS CLOSED_ON_DATE,
        STATUS AS IS_INACTIVE,
        WHENMODIFIED AS LAST_MODIFIED_DATE

    FROM {{ get_silver_source(company, 'REPORTING_PERIOD') }}
    
    {% if is_incremental() %}
    WHERE WHENMODIFIED > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }}
    )
    {% endif %}
)
SELECT *
FROM source
