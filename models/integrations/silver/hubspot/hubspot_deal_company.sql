{% set company = var('company') | upper %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem') | lower in ['hubspot'] and var('company') | lower in ['wagway', 'playfly','amh'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_DEAL_COMPANY',
    incremental_strategy = 'merge',
    unique_key = 'UNIQUE_ID'
) }}

WITH source AS (

    SELECT *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_DEAL_COMPANY') }}

    {% if is_incremental() %}
        WHERE _FIVETRAN_SYNCED > (
            SELECT dateadd(day, -1, coalesce(max(_FIVETRAN_SYNCED)), '1900-01-01')
            FROM {{ this }}
        )
        AND 1 = 1
    {% else %}
        WHERE 1 = 1
    {% endif %}

),

cleaned AS (

    SELECT
        HASH(DEAL_ID,'_',COMPANY_ID,'_',TYPE_ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'MMDDYYYY')) AS UNIQUE_ID,
        DEAL_ID,
        CATEGORY,
        COMPANY_ID,
        TYPE_ID,
        _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE

    FROM source
)

SELECT *
FROM cleaned
