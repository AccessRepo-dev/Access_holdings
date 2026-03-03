{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "hubspot") | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower)
        in ["hubspot", "hubspot_pawville"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        materialized="incremental",
        database=get_target_database(company),
        alias=sourcesystem ~ "_DEAL",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}


with
    source as (
        select CONCAT(DEAL_ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) AS ID_DATE_KEY, 
            {{ hs_canonical_deal(company, sourcesystem) }}, 
            _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            DBT_VALID_FROM,
            DBT_VALID_TO,
            CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE
    FROM  {{ ref("hubspot_deal_snapshot") }}
        {% if is_incremental() %}
            where
                (
                    property_hs_lastmodifieddate > (
                        select
                            dateadd(
                                day,
                                -3,
                                coalesce(
                                    max(property_hs_lastmodifieddate), '1900-01-01'
                                )
                            )
                        from {{ this }}
                    )
                    or (
                        dbt_valid_to > (
                            select
                                dateadd(
                                    day, -3, coalesce(max(dbt_valid_to), '1900-01-01')
                                )
                            from {{ this }}
                        )
                    )
                )
        {% else %} where 1 = 1
        {% endif %}
    ),

    cleaned as (

        select
            ID_DATE_KEY AS ID_DATE_KEY,
            CAST(DEAL_ID AS NUMBER) AS DEAL_ID,
            TRIM(PROPERTY_DEALNAME) AS PROPERTY_DEALNAME,
            CAST(PROPERTY_LOCATION_ID AS INT) AS PROPERTY_LOCATION_ID,
            TRIM(PROPERTY_PRODUCT_GROUP) AS PROPERTY_PRODUCT_GROUP,
            PROPERTY_AMOUNT AS PROPERTY_AMOUNT,
            TRIM(DEAL_PIPELINE_ID) AS DEAL_PIPELINE_ID,
            TRIM(DEAL_PIPELINE_STAGE_ID) AS DEAL_PIPELINE_STAGE_ID,
            CAST(TRIM(PROPERTY_CLOSEDATE) AS TIMESTAMP_NTZ) AS PROPERTY_CLOSEDATE,
            CAST(TRIM(PROPERTY_CREATEDATE) AS TIMESTAMP_NTZ) AS PROPERTY_CREATEDATE,
            CAST(TRIM(PROPERTY_HS_CREATEDATE) AS TIMESTAMP_NTZ) AS PROPERTY_HS_CREATEDATE,
            CAST(TRIM(PROPERTY_HS_LASTMODIFIEDDATE) AS TIMESTAMP_NTZ) AS PROPERTY_HS_LASTMODIFIEDDATE,
            CAST(TRIM(OWNER_ID) AS NUMBER) AS OWNER_ID,
            TRIM(PROPERTY_HS_ALL_OWNER_IDS) AS PROPERTY_HS_ALL_OWNER_IDS,
            TRIM(PROPERTY_DEALTYPE) AS PROPERTY_DEALTYPE,
            CAST(TRIM(PROPERTY_HS_FORECAST_AMOUNT) AS FLOAT) AS PROPERTY_HS_FORECAST_AMOUNT,
            CAST(TRIM(PROPERTY_HS_DEAL_STAGE_PROBABILITY) AS FLOAT) AS PROPERTY_HS_DEAL_STAGE_PROBABILITY,
            TRIM(PROPERTY_SERVICE_REQUEST) AS PROPERTY_SERVICE_REQUEST,
            TRIM(PROPERTY_PROPERTY_SOURCE) AS PROPERTY_PROPERTY_SOURCE,
            TRIM(PROPERTY_DESCRIPTION) AS PROPERTY_DESCRIPTION,
            PROPERTY_HS_IS_CLOSED_WON AS PROPERTY_HS_IS_CLOSED_WON,
            PROPERTY_HS_IS_CLOSED_LOST AS PROPERTY_HS_IS_CLOSED_LOST,
            TRIM(PROPERTY_CLUB_C) AS PROPERTY_CLUB_C,
            TRIM(PROPERTY_SERVICE_TYPE) AS PROPERTY_SERVICE_TYPE,
            TRIM(PROPERTY_SERVICE_CATEGORY) AS PROPERTY_SERVICE_CATEGORY,
            REPLACE(TRIM(PROPERTY_HS_ANALYTICS_SOURCE), '_', ' ') AS PROPERTY_HS_ANALYTICS_SOURCE,
            CAST(TRIM(PROPERTY_HS_PROJECTED_AMOUNT) AS FLOAT) AS PROPERTY_HS_PROJECTED_AMOUNT,
            CAST(PROPERTY_INVOICE_ID AS NUMBER) AS PROPERTY_INVOICE_ID,
            PROPERTY_CLOSED_LOST_REASON,
            SILVER_LOAD_DATE::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
            CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
            _FIVETRAN_SYNCED AS _FIVETRAN_SYNCED,
            IS_ACTIVE AS IS_ACTIVE

        FROM source
    )

select *
from cleaned
