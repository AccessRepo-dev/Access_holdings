{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("company", "wagway") | lower) in ["wagway"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_hr_company",
        incremental_strategy="merge",
        unique_key="dim_company_id",
    )
}}


with source as (select distinct id,ein_name from {{ ref("ukg_ready_lookup_eins") }})

select
    id as dim_company_id,
    id as company_id,
    null as company_code,
    ein_name as company_name,
    current_timestamp() as gold_load_date
from source
