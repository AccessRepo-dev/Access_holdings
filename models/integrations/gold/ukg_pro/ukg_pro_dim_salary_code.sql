{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly","spotless"],
        database=get_target_database(company),
        alias="dim_salary_code",
        incremental_strategy="merge",
    )
}}

{%if company == 'playfly'%} }
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


{%else%}
SELECT 
    dim_earning_id,
    description,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS gold_load_date
FROM (
    VALUES 
        (1, 'Total Tax Amount'),
        (2, 'Total Deduction Amount'),
        (3, 'Net Amount')
) AS t(dim_earning_id, description)
{%endif%}
