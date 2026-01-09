{% set company = var('company') %}
{{ config(enabled =  (var('company', 'none') | lower in [ 'playfly','amh'] and   var('sourcesystem', 'none') | lower in ['hubspot']) )}}
{{ config(
    database = get_target_database(company),
    alias = 'dim_product',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

SELECT
    id_date_key,
    product_id,
    product_name,
    property_description,
    property_family,
    portal_id,
    pricing_model,
    product_status.
    product_type,
    property_hs_folder_id,
    price,
    created_at,
    is_deleted,
    b.DEAL_ID AS OPPORTUNITY_ID

FROM {{ get_silver_source(company , 'HUBSPOT_PRODUCT') }} p
LEFT JOIN {{ get_silver_source(company , 'HUBSPOT_LINE_ITEM') }}  d on p.product_id = d.product_id
LEFT JOIN {{ get_silver_source(company , 'HUBSPOT_LINE_ITEM_DEAL') }} b on d.ID = b.LINE_ITEM_ID

