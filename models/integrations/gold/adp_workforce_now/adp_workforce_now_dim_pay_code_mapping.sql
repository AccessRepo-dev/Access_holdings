{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower) in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_pay_code_mapping",
        incremental_strategy="merge",
        unique_key="PAY_CODE",
    )
}}

with
    source as (
        select
            TRIM(PAY_CODE) as PAY_CODE,
            TRIM(BUCKET) as BUCKET,
            current_timestamp()::timestamp_ntz as gold_load_date

        FROM  {{ source('zeus_adp_workforce_now_silver', 'pay_code_mapping') }} 

    )
select *
from source