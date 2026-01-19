{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot", "hubspot_pawville"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        database=get_target_database(company),
        alias="dim_opportunity_line",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="LINE_ITEM_ID",
    )
}}

select
    *,
    {% if company == "wagway" %} 'HUBSPOT_PUPS' as source_schema,

    {% else %} concat('HUBSPOT_', '{{company | upper}}') as source_schema,

    {% endif %}

    current_timestamp()::timestamp_ntz as gold_load_date

from {{ ref('hubspot_line_item_deal_current') }}

{% if company == "wagway" %}

    union all

    select
        *,
        'HUBSPOT_PAWVILLE' as source_schema,
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_LINE_ITEM_DEAL") }} u
{% endif %}
