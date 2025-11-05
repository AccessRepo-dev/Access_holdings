{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'salesforce',
    database = get_target_database(company),
    schema = 'silver',
    unique_key = 'id',
    materialized = 'incremental',
    incremental_strategy = 'merge'
) }}

with raw as 
(
select *

from {{ get_silver_source(company, 'SALESFORCE_USER') }}
{% if is_incremental() %}
    where 
        LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
            from {{ this }})
        and DBT_VALID_TO is null
{% else %}
    where DBT_VALID_TO is null
{% endif %}
    
)

select
    TRIM(ID) AS ID,
    TRIM(USERNAME) AS USERNAME,
    EMAIL,
    ALIAS,
    TRIM(FIRST_NAME) AS FIRST_NAME,
    TRIM(LAST_NAME) AS LAST_NAME,
    TRIM(USER_ROLE_ID) AS USER_ROLE_ID,
    TRIM(PROFILE_ID) AS PROFILE_ID,
    TRIM(TITLE) AS TITLE,
    TRIM(DEPARTMENT) AS DEPARTMENT,
    TRIM(MANAGER_ID) AS MANAGER_ID,
    CREATED_DATE,
    LAST_LOGIN_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    TIME_ZONE_SID_KEY,
    LOCALE_SID_KEY,
    TRIM(LANGUAGE_LOCALE_KEY) AS LANGUAGE_LOCALE_KEY
from raw
