{% set company = var('company', 'Unknown company') | lower %}

{{ config(
    database = get_target_database(company),
) }}

with source_data as (

    {% if company == 'wagway' %}
        select * from {{ source('wagway_netsuite_raw', 'ACCOUNT') }}
    {% elif company == 'playfly' %}
        select * from {{ source('playfly_netsuite_raw', 'ACCOUNT') }}
    {% else %}
        {{ exceptions.raise_compiler_error("Unknown company: " ~ company) }}
    {% endif %}

),

cleaned as (
    select *
    from source_data
)

select * from cleaned
