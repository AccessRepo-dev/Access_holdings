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
    p.id_date_key,
    p.product_id,
    p.product_name,
    p.property_description,
    p.property_family,
    p.portal_id,
    p.pricing_model,
    p.product_status,
    p.product_type,
    p.property_hs_folder_id,
    p.price,
    p.created_at,
    b.DEAL_ID AS OPPORTUNITY_ID

FROM {{ get_silver_source(company , 'HUBSPOT_PRODUCT') }} p
LEFT JOIN {{ get_silver_source(company , 'HUBSPOT_LINE_ITEM') }}  d on p.product_id = d.product_id
LEFT JOIN {{ get_silver_source(company , 'HUBSPOT_LINE_ITEM_DEAL') }} b on d.ID = b.LINE_ITEM_ID
where     is_deleted <> TRUE
