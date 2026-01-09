{% set company = var('company', 'zeus') | lower %}
{{ config(enabled = var('sourcesystem', 'salesforce') == 'salesforce') }}
{{ config(enabled = var('company', 'zeus') == 'zeus'  and   var('sourcesystem', 'salesforce') | lower in ['salesforce']) }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_product',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}


SELECT
    p.ID_DATE_KEY,
    p.PRODUCT_ID,
    p.NAME,
    p.DESCRIPTION AS property_description,
    p.FAMILY AS property_family,
    CAST(NULL AS INT) AS portal_id,
    CAST(NULL AS INT) AS pricing_model,
    NULL AS product_status ,
    p.PRODUCT_CODE AS product_type,
    CAST(NULL AS INT) AS property_hs_folder_id,
    CAST(NULL AS INT) AS price,
    p.created_date as created_at,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE,
    ol.OPPORTUNITY_ID

FROM {{ get_silver_source(company , 'SALESFORCE_PRODUCT') }} p
LEFT JOIN {{ get_silver_source(company , 'SALESFORCE_OPPORTUNITY_LINE_ITEM') }} ol on p.product_id = ol.PRODUCT_2_ID


