{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (

    select
        sc.ID_DATE_KEY,
        sc.CASE_ID,
        sc.ACCOUNT_ID,
        dc.CONTACT_ID,
        du.ID AS USER_ID,
        sc.IS_ACTIVE,
        sc.STATUS AS CASE_STATUS
    FROM {{ get_silver_source(company, 'SALESFORCE_CASE') }} sc
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_CONTACT') }} dc 
           ON sc.contact_id = dc.contact_id AND dc.IS_ACTIVE = 1
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_USER') }} du 
           ON sc.OWNER_ID = du.ID AND du.IS_ACTIVE = 1

)
select *
from source