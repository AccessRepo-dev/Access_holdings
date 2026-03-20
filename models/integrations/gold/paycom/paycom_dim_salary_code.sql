{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "paycom") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
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

