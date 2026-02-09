{% set company = var('company', 'zeus') | lower %}
{{ config(enabled = var('sourcesystem', 'salesforce') == 'salesforce' and var('company','zeus') == 'zeus') }}


{{
    config(
    database = get_target_database(company),
    alias = 'fact_lead',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (


    select
        CONCAT(LEAD_ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        sl.LEAD_ID,
        cast(sl.CREATED_DATE as date) AS LEAD_DATE,
        sl.owner_id AS OWNER_ID,
        sl.COMPANY,
        sl.STATUS,
        case
            when
                lower(STATUS) in (
                    'working',
                    'nurturing',
                    'qualified',
                    'secure nda',
                    'nda signed',
                    'qualified target',
                    'qualified prospect'
                )
            then 'Qualified Lead'
            else 'Lead'
        end as MAPPED_LEADSTAGE,
        sl.IS_ACTIVE,
        sl.converted_opportunity_id AS CONVERTED_OPPORTUNITY_KEY,
        CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    FROM {{ ref('salesforce_lead_current') }} sl

    {% if is_incremental() %}
        WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}


)
select *
from source