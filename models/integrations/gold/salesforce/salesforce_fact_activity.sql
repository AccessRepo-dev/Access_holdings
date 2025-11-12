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
        t.ID_DATE_KEY,
        t.ACTIVITY_ID,
        u.id AS USER_ID,
        t.WHAT_ID,
        t.WHO_ID,
        t.IS_ACTIVE,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    FROM {{ get_silver_source(company, 'SALESFORCE_TASK') }} as t 
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_USER') }} as u 
           ON t.owner_id = u.id AND u.IS_ACTIVE = 1
)
select *
from source