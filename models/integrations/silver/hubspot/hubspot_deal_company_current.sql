{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
    enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot"]
    and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_DEAL_COMPANY',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

WITH source AS (

    SELECT *
    from {{ ref('hubspot_deal_company_snapshot') }}

    {% if is_incremental() %}
        WHERE 
            (_FIVETRAN_SYNCED > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01')) FROM {{ this }})
        OR 
            (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
    {% else %}
        WHERE 1 = 1
    {% endif %}

),

cleaned AS (

    SELECT
        CONCAT(DEAL_ID,'_',COMPANY_ID,'_',TYPE_ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) AS ID_DATE_KEY,
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
