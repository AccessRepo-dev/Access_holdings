{% set company = var('company', 'wagway') | lower %}
{% set sourcesystem  = var('sourcesystem', 'ringcentral') | lower %}

{{ config(enabled =(var('sourcesystem','ringcentral')| lower) =='ringcentral') }}

{{ config(
    database=get_target_database(var('company','wagway')),
    materialized = 'table',
    unique_key = ['EXTENSION_ID', 'DAY', 'INDEX']
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'USER_BUSINESS_HOUR_RANGE') }}
),

cleaned as 
(
    select
    TRIM(EXTENSION_ID) AS EXTENSION_ID,
	TRIM(DAY) AS DAY,
	CAST(TRIM(INDEX) AS INT) AS INDEX,
	TRIM("FROM") AS "FROM",
	TRIM("TO") AS "TO",
	CAST(TRIM(_FIVETRAN_SYNCED) AS TIMESTAMP_TZ) AS _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
