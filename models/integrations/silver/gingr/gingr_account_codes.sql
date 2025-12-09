{% set company = var('company','wagway') %}
{% set sourcesystem = var('sourcesystem','gingr') %}

{{ config(enabled =  (var('sourcesystem','gingr')| lower) == 'gingr') }}

{{ config(
    database=get_target_database(var('company','wagway')),
    materialized = 'table',
    unique_key = ['ID','SOURCE_DB']
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'ACCOUNT_CODES') }}
),

cleaned as 
(
    select
    CAST(ID AS INT) AS ID,
	TRIM(SOURCE_DB) AS SOURCE_DB,
	TRIM(CODE) AS CODE,
	TRIM(LABEL) AS LABEL,
	CAST(PARENT_ID AS INT) AS PARENT_ID,
	CAST(TRIM(IS_DELETED) AS BOOLEAN) AS IS_DELETED,
	CAST(TRIM(ODS_LAST_UPDATE_DATE) AS TIMESTAMP_NTZ) AS ODS_LAST_UPDATE_DATE,
	TRIM(DELETE_INDICATOR) AS DELETE_INDICATOR,
	CAST(TRIM(_FIVETRAN_DELETED) AS BOOLEAN) AS _FIVETRAN_DELETED,
	CAST(TRIM(_FIVETRAN_SYNCED) AS TIMESTAMP_TZ) AS _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
