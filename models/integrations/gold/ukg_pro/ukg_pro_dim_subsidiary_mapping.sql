{% set company = var("company", "playfly") | lower %}
{{ config(enabled=var("sourcesystem", "ukg_pro") | lower == "ukg_pro") }}

{{
    config(
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_subsidiary_mapping",
        incremental_strategy="merge",
        unique_key="subsidiary_id",
    )
}}

with
    source as (
        select
            Finance_ID as DIM_SUBSIDIARY_ID,
            FINANCE_SUBSIDIARY_NAME as SUBSIDIARY_NAME,
            HR_Company_Name AS COMPANY_NAME,
            HR_ID as DIM_COMPANY_ID,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("subsidiary_mapping") }}

    )
select *
from source