{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "paycom") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_location_mapping",
        incremental_strategy="merge",
        unique_key="dim_location_id",
    )
}}

with
    source as (
        select
            b.DIM_LOCATION_ID AS DIM_HR_LOCATION_ID,
            a.LOCATION_NAME,
            a.DIM_LOCATION_ID,
            a.HR_SHORT_NAME AS HR_LOCATION_NAME,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ source('amh_paycom_silver',"amh_location_mapping") }} a
        left join {{ref('paycom_dim_location')}} b on b.LOCATION_NAME = a.HR_LOCATION_NAME

    )
select *
from source