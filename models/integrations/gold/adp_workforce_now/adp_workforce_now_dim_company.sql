{% set company = var("company", "zeus") | lower %}
{{
    config(
        enabled=var("sourcesystem", "adp_workforce_now") | lower
        == "adp_workforce_now"
    )
}}

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
            id as dim_company_id,
            null as company_code,
            coalesce(name_short_name, name_long_name, 'Unknown') as company_name,
            current_timestamp()::timestamp_ntz as gold_load_date

        from {{ ref("adp_workforce_now_organizational_unit") }}
        where lower(type_short_name) = 'business unit'

    )
select *
from source
