{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot"]
        and (var("company", "amh") | lower) in ["playfly", "amh"],
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

from {{ ref('hubspot_product_current') }} p
left join
    {{ ref('hubspot_line_item_current') }} d
    on p.product_id = d.product_id
left join
    {{ ref('hubspot_line_item_deal_current') }} b
    on d.id = b.line_item_id