{% set company = var("company", "playfly") | lower %}
{{ config(enabled=var("sourcesystem", "ukg_pro") | lower == "ukg_pro") }}

{{
    config(
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
            md5(id) as dim_company_id,
            id as company_id,
            company_code,
            company_name,
            current_timestamp()::timestamp_ntz as gold_load_date

        from {{ ref("ukg_pro_company") }}

    )
select *
from source
