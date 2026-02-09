{% set company = var('company', 'zeus') | lower %}
{{ config(enabled = var('sourcesystem', 'salesforce') == 'salesforce' and var('company','zeus') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    alias = 'fact_opportunity',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}


with hashed as (
    select
        ID,
        STAGE_NAME,
        INSTALL_AMOUNT_C,
        TOTAL_CONTRACT_VALUE_CURRENCY_C AS TCV_AMOUNT,
        OWNER_ID,
        CLOSE_DATE,
        case when o.stage_name ilike 'close%' and o.stage_name ilike '%won' then 1 else 0 end as IS_WON_N,
        case when o.stage_name ilike 'close%' then 1 else 0 end as IS_CLOSED_N,
        -- IS_CLOSED,
        -- IS_WON,
        PROBABILITY,
        ACCOUNT_ID,
        DBT_VALID_FROM,
        DBT_VALID_TO,
        md5(
            coalesce(STAGE_NAME,'') || '|' ||
            coalesce(TOTAL_CONTRACT_VALUE_CURRENCY_C::string,'') || '|' ||
            coalesce(OWNER_ID,'') || '|' ||
            coalesce(CLOSE_DATE::string,'') || '|' ||
            coalesce(IS_WON_N::string,'') || '|' ||
            coalesce(IS_CLOSED_N,'')
        ) as attr_hash
    from {{ ref('salesforce_opportunity_current') }} o

)
, scd2 as (
    select
        CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        ID as OPPORTUNITY_ID,
        OWNER_ID,
        STAGE_NAME,
        TCV_AMOUNT as AMOUNT,
        CLOSE_DATE,
        cast(IS_CLOSED_N as Boolean) as IS_CLOSED,
        cast(IS_WON_N as Boolean) as IS_WON,
        PROBABILITY,
        min(DBT_VALID_FROM) over (partition by ID, attr_hash) as DBT_VALID_FROM,
        case 
            when max(case when DBT_VALID_TO is null then 1 else 0 end) 
                    over (partition by ID, attr_hash) = 1
            then null
            else max(DBT_VALID_TO) over (partition by ID, attr_hash)
        end as DBT_VALID_TO,
        max(case when DBT_VALID_TO is null then 1 else 0 end) 
            over (partition by ID, attr_hash) as IS_ACTIVE,
        md5(
                    coalesce(STAGE_NAME, '')
                    || concat('SALESFORCE_', '{{company | upper}}')
                ) as STAGE_KEY,
        CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
        ACCOUNT_ID as DIM_COMPANY_ID,
        null as PROPERTY_HS_PROJECTED_AMOUNT,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from hashed
    qualify row_number() over (partition by ID, attr_hash order by DBT_VALID_FROM) = 1
)
select 

*
, row_number() over(partition by OPPORTUNITY_ID order by DBT_VALID_FROM) as rank
 from scd2