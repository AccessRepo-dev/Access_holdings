{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly","spotless"],
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
        {%if company == 'playfly'%}
        from {{ source('playfly_ukg_pro_silver',"playfly_subsidiary_mapping") }}
        {%else%}
        from {{ source('spotless_ukg_pro_silver',"spotless_subsidiary_mapping") }}
        {%endif%}


    )
select *
from source