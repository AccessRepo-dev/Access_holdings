{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower) in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
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

