{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_hr_company",
        incremental_strategy="merge",
        unique_key="dim_company_id",
    )
}}

with
    source as (
        select
            id as dim_company_id,
            id as company_id,
            company_code,
            company_name,
            current_timestamp()::timestamp_ntz as gold_load_date

        from {{ ref("ukg_pro_company") }}

    )
select *
from source
