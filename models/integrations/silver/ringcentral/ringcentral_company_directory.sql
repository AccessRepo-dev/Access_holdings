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
from {{ get_raw_source(company, sourcesystem, 'COMPANY_DIRECTORY') }}

),

cleaned as 
(
    select
    CAST(ID AS BIGINT) AS ID,
    TRIM(EMAIL) AS EMAIL,
    TRIM(FIRST_NAME) AS FIRST_NAME,
    TRIM(LAST_NAME) AS LAST_NAME,
    TRIM(NAME) AS NAME,
    TRIM(DEPARTMENT) AS DEPARTMENT,
    TRIM(SITE_NAME) AS SITE_NAME,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
