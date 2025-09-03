{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}

{{ config(
    database = get_target_database(company)
) }}

with source_data as (

    select * 
    from {{ get_raw_source(company, sourcesystem, 'ACCOUNT') }}

),

cleaned as (
    select *
    from source_data
)

select * from cleaned
