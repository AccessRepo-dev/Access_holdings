{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"] and var("company", "none") in ["wagway", "playfly"]) }}



{{
    config(
        database=get_target_database(company),
        alias="fact_opportunity",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

with pups_hashed as (

select
    A.deal_id as ID,
    b.label as STAGE_NAME,
    property_hs_all_owner_ids as OWNER_ID,
    A.property_amount as AMOUNT,
    A.property_closedate as CLOSE_DATE,
    cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END as Boolean) AS IS_CLOSED,
    cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = TRUE THEN 1
    ELSE 0 END as Boolean) as IS_WON,
    property_hs_deal_stage_probability as PROBABILITY,
    A.DBT_VALID_FROM,
    A.DBT_VALID_TO,
    md5(
        coalesce(STAGE_NAME,'') || '|' ||
        coalesce(property_amount::string,'') || '|' ||
        coalesce(OWNER_ID::string,'') || '|' ||
        coalesce(CLOSE_DATE::string,'') || '|' ||
        coalesce(IS_WON::string,'') || '|' ||
        coalesce(IS_CLOSED::string,'')
    ) as attr_hash
from {{ get_silver_source(company, "HUBSPOT_DEAL") }} a
join
    {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE_STAGE") }} b
    on b.stage_id = a.deal_pipeline_stage_id
    and b.is_active = 1

)


{% if company == "wagway" %}

    ,pawville_hashed as (

    select
        A.deal_id as ID,
        b.label as STAGE_NAME,
        property_hs_all_owner_ids as OWNER_ID,
        A.property_amount as AMOUNT,
        A.property_closedate as CLOSE_DATE,
        cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END as Boolean) AS IS_CLOSED,
        cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = TRUE THEN 1
        ELSE 0 END as Boolean) as IS_WON,
        property_hs_deal_stage_probability as PROBABILITY,
        A.DBT_VALID_FROM,
        A.DBT_VALID_TO,
        md5(
            coalesce(STAGE_NAME,'') || '|' ||
            coalesce(property_amount::string,'') || '|' ||
            coalesce(OWNER_ID::string,'') || '|' ||
            coalesce(CLOSE_DATE::string,'') || '|' ||
            coalesce(IS_WON::string,'') || '|' ||
            coalesce(IS_CLOSED::string,'')
        ) as attr_hash
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a
    join
        {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_PIPELINE_STAGE") }} b
        on b.stage_id = a.deal_pipeline_stage_id
        and b.is_active = 1

    )

{% endif %}


select
        CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        ID as OPPORTUNITY_ID,
        md5(   
        coalesce(nullif(cast(OWNER_ID as string),''), '') || '|' ||
        coalesce('HUBSPOT','')
        ) as OWNER_ID,
        STAGE_NAME,
        AMOUNT,
        CLOSE_DATE,
        IS_CLOSED,
        IS_WON,
        PROBABILITY*100 as PROBABILITY,
        min(DBT_VALID_FROM) over (partition by ID, attr_hash) as DBT_VALID_FROM,
        case 
            when max(case when DBT_VALID_TO is null then 1 else 0 end) 
                    over (partition by ID, attr_hash) = 1
            then null
            else max(DBT_VALID_TO) over (partition by ID, attr_hash)
        end as DBT_VALID_TO,
        max(case when DBT_VALID_TO is null then 1 else 0 end) 
            over (partition by ID, attr_hash) as IS_ACTIVE,
        {% if company == "wagway" %}
            'HUBSPOT_PUPS' as SOURCE_SCHEMA,

        {%else%}

        CONCAT('HUBSPOT_','{{company | upper}}') as SOURCE_SCHEMA,

        {% endif %}
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from pups_hashed
    qualify row_number() over (partition by ID, attr_hash order by DBT_VALID_FROM) = 1

{% if company == "wagway" %}
    union all

    select
        CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        ID as OPPORTUNITY_ID,
        md5(   
        coalesce(nullif(cast(OWNER_ID as string),''), '') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as OWNER_ID,
        STAGE_NAME,
        AMOUNT,
        CLOSE_DATE,
        IS_CLOSED,
        IS_WON,
        PROBABILITY*100 as PROBABILITY,
        min(DBT_VALID_FROM) over (partition by ID, attr_hash) as DBT_VALID_FROM,
        case 
            when max(case when DBT_VALID_TO is null then 1 else 0 end) 
                    over (partition by ID, attr_hash) = 1
            then null
            else max(DBT_VALID_TO) over (partition by ID, attr_hash)
        end as DBT_VALID_TO,
        max(case when DBT_VALID_TO is null then 1 else 0 end) 
            over (partition by ID, attr_hash) as IS_ACTIVE,
        'HUBSPOT_PAWVILLE' as SOURCE_SCHEMA,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    from pawville_hashed
    qualify row_number() over (partition by ID, attr_hash order by DBT_VALID_FROM) = 1

{% endif %}
