{% set company = var("company") %}
{% set sourcesystem = var("sourcesystem") | upper %}


{{
    config(
        enabled=(var("sourcesystem") | lower) in ["hubspot", "hubspot_pawville"]
        and (var("company") | lower) in ["wagway", "playfly", "amh"],
        database=get_target_database(company),
        alias="fact_opportunity_line",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

select *,
    {% if company == "wagway" %} 'HUBSPOT_PUPS' as source_schema,

    {% else %} concat('HUBSPOT_', '{{company | upper}}') as source_schema,

    {% endif %}

    current_timestamp()::timestamp_ntz as gold_load_date
from {{ get_silver_source(company, "HUBSPOT_LINE_ITEM") }}
{% if company == "wagway" %}

    union all

    select *,
        'HUBSPOT_PAWVILLE' as source_schema,
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_LINE_ITEM") }} u
{% endif %}
