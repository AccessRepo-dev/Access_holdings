{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled =(var('company') | lower) ==  'wagway' and (var('sourcesystem')| lower) =='ringcentral') }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['SMS_ID','VALUE']
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'SMS_TO') }}
{% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )

{% endif %}

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
