
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'REPORTING_PERIOD_ID'
) }}

with source as (
    SELECT 
        RECORDNO AS PERIOD_ID,
        NAME AS PERIOD_NAME,
        START_DATE AS START_DATE,
        END_DATE AS END_DATE,
        NULL AS CLOSED_ON_DATE,
        STATUS AS IS_INACTIVE,
        WHENMODIFIED AS LAST_MODIFIED_DATE

    FROM {{ get_silver_source(company, 'sage_reporting_period') }}
    
    {% if is_incremental() %}
    and WHENMODIFIED > (
        SELECT coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        FROM {{ this }}
    )
    {% endif %}
)
SELECT *
FROM source
