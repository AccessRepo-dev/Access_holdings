{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'OPPORTUNITY_ID'
) }}

with source as (

    select
        op.id as OPPORTUNITY_ID,
        ac.ACCOUNT_ID,
        u.ID AS USER_ID,
        op.STAGE_NAME,
        CAST(op.AMOUNT AS NUMBER) AS AMOUNT,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    FROM {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }}  as op
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_ACCOUNT') }} as ac
        ON op.account_id=ac.account_id
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_USER') }} u 
        ON op.owner_id = u.id


)
select *
from source