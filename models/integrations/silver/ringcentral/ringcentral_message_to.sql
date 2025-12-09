{% set company = var('company', 'wagway') | lower %}
{% set sourcesystem  = var('sourcesystem', 'ringcentral') | lower %}

{{ config(enabled =(var('sourcesystem','ringcentral')| lower) =='ringcentral') }}

{{ config(
    database=get_target_database(var('company','wagway')),
    materialized = 'table',
    unique_key = ['MESSAGE_ID', '_FIVETRAN_ID']
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'MESSAGE_TO') }}
),

cleaned as 
(
    select
    CAST(MESSAGE_ID AS BIGINT) AS MESSAGE_ID,
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
