{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(enabled =(var('company') | lower) ==  'wagway' and (var('sourcesystem')| lower) =='ringcentral') }}

{{ config(
    database=get_target_database(var('company')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['MESSAGE_ID', '_FIVETRAN_ID']
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'MESSAGE_TO') }}
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
    CAST(TRIM(MESSAGE_ID) AS BIGINT) AS MESSAGE_ID,
	TRIM(_FIVETRAN_ID) AS _FIVETRAN_ID,
	TRIM(EXTENSION_ID) AS EXTENSION_ID,
	TRIM(EXTENSION_NUMBER) AS EXTENSION_NUMBER,
	TRIM(LOCATION) AS LOCATION,
	CAST(TRIM(TARGET) AS BOOLEAN) AS TARGET,
	TRIM(MESSAGE_STATUS) AS MESSAGE_STATUS,
	TRIM(FAX_ERROR_CODE) AS FAX_ERROR_CODE,
	TRIM(NAME) AS NAME,
	TRIM(PHONE_NUMBER) AS PHONE_NUMBER,
	CAST(TRIM(_FIVETRAN_SYNCED) AS TIMESTAMP_TZ) AS _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
