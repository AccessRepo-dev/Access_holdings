{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot", "hubspot_pawville"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        database=get_target_database(company),
        alias="dim_sales_channel",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["ID", "SOURCE_SCHEMA"],
    )
}}


select distinct
    md5(
        coalesce(nullif(a.property_hs_analytics_source, ''), '')
        || '|'
        || coalesce('HUBSPOT', '')
    ) as id,
    case
        when
            a.property_hs_analytics_source is null
            or a.property_hs_analytics_source = ''
        then 'UNKNOWN'
        else a.property_hs_analytics_source
    end as sales_channel,

    {% if company == "wagway" %} 'HUBSPOT_PUPS' as source_schema,

    {% else %} concat('HUBSPOT_', '{{company | upper}}') as source_schema,

    {% endif %}

    current_timestamp()::timestamp_ntz as gold_load_date
from {{ ref('hubspot_deal_current') }} a

{% if company == "wagway" %}

    union all

    select distinct
        md5(
            coalesce(nullif(a.property_hs_analytics_source, ''), '')
            || '|'
            || coalesce('HUBSPOT_PAWVILLE', '')
        ) as id,
        case
            when
                a.property_hs_analytics_source is null
                or a.property_hs_analytics_source = ''
            then 'UNKNOWN'
            else a.property_hs_analytics_source
        end as sales_channel,
        'HUBSPOT_PAWVILLE' as source_schema,
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a

{% endif %}
