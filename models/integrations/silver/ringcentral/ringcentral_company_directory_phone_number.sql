{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled =(var('company') | lower) ==  'wagway' and (var('sourcesystem')| lower) =='ringcentral') }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'table',
    unique_key = 'ID'
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'COMPANY_DIRECTORY_PHONE_NUMBER') }}
),

cleaned as 
(
    select
    TRIM(PHONE_NUMBER) AS PHONE_NUMBER,
    CAST(COMPANY_DIRECTORY_ID AS BIGINT) AS COMPANY_DIRECTORY_ID,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
