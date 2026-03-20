{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower) in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_subsidiary_mapping",
        incremental_strategy="merge",
        unique_key="subsidiary_id",
    )
}}

with
    source as (
        select
            DIM_SUBSIDIARY_ID,
            SUBSIDIARY_NAME,
            COMPANY_NAME,
            DIM_COMPANY_ID,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ source('zeus_adp_workforce_now_silver',"zeus_subsidiary_mapping") }}

    )
select *
from source