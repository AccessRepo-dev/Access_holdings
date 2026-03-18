{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("company", "wagway") | lower) in ["wagway"],
        database=get_target_database(company),
        alias="dim_salary_code",
        incremental_strategy="merge",
    )
}}


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

