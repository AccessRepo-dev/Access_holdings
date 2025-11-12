{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'LEAD_ID'
) }}

with source as (


    select
        sl.ID_DATE_KEY,
        sl.LEAD_ID,
        sl.CREATED_DATE AS LEAD_DATE,
        du.id AS OWNER_ID,
        sl.COMPANY,
        sl.STATUS,
        sl.IS_ACTIVE,
        fo.id AS CONVERTED_OPPORTUNITY_KEY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    FROM {{ get_silver_source(company, 'SALESFORCE_LEAD') }} sl
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_USER') }} du 
           ON sl.owner_id = du.id AND du.IS_ACTIVE = 1
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }} fo
           ON sl.converted_opportunity_id = fo.id AND fo.IS_ACTIVE = 1


)
select *
from source