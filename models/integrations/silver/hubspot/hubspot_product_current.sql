{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "hubspot") | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower)
        in ["hubspot"]
        and (var("company", "amh") | lower) in ["playfly", "amh"],
        materialized="incremental",
        database=get_target_database(company),
        alias=sourcesystem ~ "_PRODUCT",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

with
    source as (
        select  CONCAT(ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) AS ID_DATE_KEY, 
            {{ hs_canonical_product(company, sourcesystem) }}, 
            _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            DBT_VALID_FROM,
            DBT_VALID_TO,
            CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE,
                        COALESCE(_fivetran_deleted, false) AS IS_DELETED,
        from {{ ref('hubspot_products_snapshot') }}

        {% if is_incremental() %}
            where
                (
                    _fivetran_synced > (
                        select
                            dateadd(
                                day, -3, coalesce(max(_fivetran_synced), '1900-01-01')
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
        select ID_DATE_KEY AS ID_DATE_KEY,
                CAST(PRODUCT_ID AS INT) AS PRODUCT_ID,
                INITCAP(TRIM(PRODUCT_NAME)) AS PRODUCT_NAME,
                INITCAP(TRIM(PROPERTY_DESCRIPTION)) AS PROPERTY_DESCRIPTION,
                INITCAP(TRIM(PROPERTY_FAMILY)) AS PROPERTY_FAMILY,
                PORTAL_ID::NUMBER AS PORTAL_ID,
                LOWER(TRIM(PRICING_MODEL)) AS PRICING_MODEL,
                LOWER(TRIM(PRODUCT_STATUS)) AS PRODUCT_STATUS,
                LOWER(TRIM(PRODUCT_TYPE)) AS PRODUCT_TYPE,
                TRIM(PROPERTY_HS_FOLDER_ID) AS PROPERTY_HS_FOLDER_ID,
                CAST(PRICE AS FLOAT) AS PRICE,
                CREATED_AT AS CREATED_AT,
                UPDATED_AT AS UPDATED_AT,
                SILVER_LOAD_DATE::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
                CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
                CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
                _FIVETRAN_SYNCED AS _FIVETRAN_SYNCED,
                IS_ACTIVE AS IS_ACTIVE,
                IS_DELETED AS IS_DELETED
        from source
    )

select *
from cleaned