{% set company = var('company', 'zeus') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

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
        OWNER_ID,
        CLOSE_DATE,
        IS_CLOSED,
        IS_WON,
        PROBABILITY,
        DBT_VALID_FROM,
        DBT_VALID_TO,
        md5(
            coalesce(STAGE_NAME,'') || '|' ||
            coalesce(INSTALL_AMOUNT_C::string,'') || '|' ||
            coalesce(OWNER_ID,'') || '|' ||
            coalesce(CLOSE_DATE::string,'') || '|' ||
            coalesce(IS_WON::string,'') || '|' ||
            coalesce(IS_CLOSED,'')
        ) as attr_hash
    from {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }}

)
, scd2 as (
    select
        CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        ID as OPPORTUNITY_ID,
        OWNER_ID,
        STAGE_NAME,
        INSTALL_AMOUNT_C as AMOUNT,
        CLOSE_DATE,
        IS_CLOSED,
        IS_WON,
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
        CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from hashed
    qualify row_number() over (partition by ID, attr_hash order by DBT_VALID_FROM) = 1
)
select * from scd2