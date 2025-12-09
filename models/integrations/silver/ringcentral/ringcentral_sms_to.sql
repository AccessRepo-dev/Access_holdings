{% set company = var('company', 'wagway') | lower %}
{% set sourcesystem  = var('sourcesystem', 'ringcentral') | lower %}

{{ config(enabled =(var('sourcesystem','ringcentral')| lower) =='ringcentral') }}

{{ config(
    
    database=get_target_database(var('company','wagway')),
    materialized = 'table',
    unique_key = ['SMS_ID','VALUE']
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'SMS_TO') }}
),

cleaned as 
(
    select
        CAST(SMS_ID AS BIGINT) AS SMS_ID,
        TRIM(VALUE) AS VALUE,
        CAST(_FIVETRAN_SYNCED AS TIMESTAMP_TZ) AS _fivetran_synced,
        'PUPS Pets Club' AS COMPANY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
