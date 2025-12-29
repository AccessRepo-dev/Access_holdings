{% set company = var("company", "wagway") %}
{{
    config(
        enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"]
        and var("company", "none") in ["wagway", "playfly", "amh"]
    )
}}


{{
    config(
        database=get_target_database(company),
        alias="dim_stage_mapping",
        materialized="incremental",
        incremental_strategy="merge",
    )
}}

{% set derived_metrics = var("derived_metrics") %}

select
    stage_name,
    mapped_stage_name,
    cast(sort_order as int) + 1 as stage_order,

    {% if company == "wagway" %}
        md5(coalesce(stage_name, '') || '|HUBSPOT_PUPS') as stage_key,
        'HUBSPOT_PUPS' as source_schema,

    {% else %}
        md5(
            coalesce(stage_name, '') || concat('HUBSPOT_', '{{company | upper}}')
        ) as stage_key,
        concat('HUBSPOT_', '{{company | upper}}') as source_schema,

    {% endif %}

    current_timestamp()::timestamp_ntz as gold_load_date
from {{ get_silver_source(company, company | upper ~ "_OPPORTUNITY_STAGE_MAPPING") }}

{% if company != "amh" %}
    union

    select
        'Lead' as stage_name,
        'Lead' as mapped_stage_name,
        1 as stage_order,
        {% if company == "wagway" %}
            md5(coalesce('Lead', '') || '|HUBSPOT_PUPS') as stage_key,
            'HUBSPOT_PUPS' as source_schema,

        {% else %}
            md5(
                coalesce('Lead', '') || concat('HUBSPOT_', '{{company | upper}}')
            ) as stage_key,
            concat('HUBSPOT_', '{{company | upper}}') as source_schema,

        {% endif %}
        current_timestamp()::timestamp_ntz as gold_load_date
    from
        {{ get_silver_source(company, company | upper ~ "_OPPORTUNITY_STAGE_MAPPING") }}

{% endif %}

{% if company == "wagway" %}

    union all

    select
        stage_name,
        mapped_stage_name,
        cast(sort_order as int) + 1 as stage_order,

        {% if company == "wagway" %}
            md5(coalesce(stage_name, '') || '|HUBSPOT_PAWVILLE') as stage_key,
            'HUBSPOT_PAWVILLE' as source_schema,

        {% else %}
            md5(
                coalesce(stage_name, '') || concat('HUBSPOT_', '{{company | upper}}')
            ) as stage_key,
            concat('HUBSPOT_', '{{company | upper}}') as source_schema,

        {% endif %}
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "WAGWAY_PAWVILLE_OPPORTUNITY_STAGE_MAPPING") }}

    union

    select
        'Lead' as stage_name,
        'Lead' as mapped_stage_name,
        1 as stage_order,
        md5(coalesce('Lead', '') || '|HUBSPOT_PAWVILLE') as stage_key,
        'HUBSPOT_PAWVILLE' as source_schema,
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "WAGWAY_PAWVILLE_OPPORTUNITY_STAGE_MAPPING") }}

{% endif %}
