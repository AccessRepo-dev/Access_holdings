{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
        database=get_target_database(company),
        alias="dim_salary_code",
        incremental_strategy="merge",
    )
}}

with
    source as (
        select
            id as dim_earning_id,
            long_description as description,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("ukg_pro_earning") }}
        where _fivetran_deleted = false
    )
select *
from source
