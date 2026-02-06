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

        from {{ ref("pay_code_mapping") }}

    )
select *
from source