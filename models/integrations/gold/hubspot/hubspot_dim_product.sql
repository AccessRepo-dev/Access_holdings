{% set company = var("company") %}
{% set sourcesystem = var("sourcesystem") | upper %}


{{
    config(
        enabled=(var("sourcesystem") | lower) in ["hubspot", "hubspot_pawville"]
        and (var("company") | lower) in ["playfly", "amh"],
        database=get_target_database(company),
        alias="dim_product",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

select p.*,
b.deal_id as opportunity_id,
concat('HUBSPOT_', '{{company | upper}}') as source_schema,
current_timestamp()::timestamp_ntz as gold_load_date

from {{ get_silver_source(company, "HUBSPOT_PRODUCT") }} p
left join
    {{ get_silver_source(company, "HUBSPOT_LINE_ITEM") }} d
    on p.product_id = d.product_id
left join
    {{ get_silver_source(company, "HUBSPOT_LINE_ITEM_DEAL") }} b
    on d.id = b.line_item_id
