{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"] and var("company", "none") in ["wagway", "playfly","amh"]) }}



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
    PROPERTY_DEALNAME,
    CONTACT_ID,
    CASE 
            WHEN contact_id IS NULL THEN NULL
            ELSE MIN(
                CASE 
                    WHEN (property_invoice_id IS NOT NULL OR label ILIKE '%purchase%') 
                        THEN LEAST(property_closedate, property_createdate) 
                END
            ) OVER (PARTITION BY contact_id)
        END AS acquisition_date,
    PROPERTY_HS_IS_CLOSED_LOST,
     CASE 
            WHEN property_createdate > property_closedate THEN property_closedate 
            ELSE property_createdate 
        END AS property_createdate,
    MIN(property_createdate) OVER (PARTITION BY contact_id) AS contact_date,
    b.label as STAGE_NAME,
    owner_id as OWNER_ID,
    A.property_amount as AMOUNT,
    A.property_closedate as CLOSE_DATE,
    case when dsm.mapped_stage_name ilike 'close%' and dsm.mapped_stage_name ilike '%won' then 1 else 0 end as IS_WON_N,
    case when dsm.mapped_stage_name ilike 'close%' then 1 else 0 end as IS_CLOSED_N,
    -- cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END as Boolean) AS IS_CLOSED,
    -- cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = TRUE THEN 1
    -- ELSE 0 END as Boolean) as IS_WON,
    property_hs_deal_stage_probability as PROBABILITY,
    A.DBT_VALID_FROM,
    A.DBT_VALID_TO,
    md5(
        coalesce(STAGE_NAME,'') || '|' ||
        coalesce(property_amount::string,'') || '|' ||
        coalesce(OWNER_ID::string,'') || '|' ||
        coalesce(CLOSE_DATE::string,'') || '|' ||
        coalesce(IS_WON_N::string,'') || '|' ||
        coalesce(IS_CLOSED_N::string,'')
    ) as attr_hash
from {{ get_silver_source(company, "HUBSPOT_DEAL") }} a
left join {{ get_silver_source(company, "HUBSPOT_DEAL_CONTACT") }} c
on a.DEAL_ID = c.DEAL_ID

left join
    {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE_STAGE") }} b
    on b.stage_id = a.deal_pipeline_stage_id
    and b.is_active = 1
left join
        {{ ref("hubspot_dim_stage_mapping") }} dsm on b.label = dsm.stage_name
        {% if company == "wagway" %} and dsm.source_schema = 'HUBSPOT_PUPS'
        {% else %} and dsm.source_schema = concat('HUBSPOT_', '{{ company | upper }}')
        {% endif %}

)
{% if company == "wagway" %}

    ,pawville_hashed as (

    select
        A.deal_id as ID,
        PROPERTY_DEALNAME,
        CONTACT_ID,
            CASE 
            WHEN contact_id IS NULL THEN NULL
            ELSE MIN(
                CASE 
                    WHEN (property_invoice_id IS NOT NULL OR label ILIKE '%purchase%') 
                        THEN LEAST(property_closedate, property_createdate) 
                END
            ) OVER (PARTITION BY contact_id)
        END AS acquisition_date,
        PROPERTY_HS_IS_CLOSED_LOST,
           CASE 
            WHEN property_createdate > property_closedate THEN property_closedate 
            ELSE property_createdate 
        END AS property_createdate,
        MIN(property_createdate) OVER (PARTITION BY contact_id) AS contact_date,
        b.label as STAGE_NAME,
        owner_id as OWNER_ID,
        A.property_amount as AMOUNT,
        A.property_closedate as CLOSE_DATE,
        case when dsmm.mapped_stage_name ilike 'close%' and dsmm.mapped_stage_name ilike '%won' then 1 else 0 end as IS_WON_N,
        case when dsmm.mapped_stage_name ilike 'close%' then 1 else 0 end as IS_CLOSED_N,
        -- cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END as Boolean) AS IS_CLOSED,
        -- cast(CASE WHEN A.property_closedate < CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won = TRUE THEN 1
        -- ELSE 0 END as Boolean) as IS_WON,
        property_hs_deal_stage_probability as PROBABILITY,
        A.DBT_VALID_FROM,
        A.DBT_VALID_TO,
        md5(
            coalesce(STAGE_NAME,'') || '|' ||
            coalesce(property_amount::string,'') || '|' ||
            coalesce(OWNER_ID::string,'') || '|' ||
            coalesce(CLOSE_DATE::string,'') || '|' ||
            coalesce(IS_WON_N::string,'') || '|' ||
            coalesce(IS_CLOSED_N::string,'')
        ) as attr_hash
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a
    left join {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_CONTACT") }} c
    on a.DEAL_ID = c.DEAL_ID
    left join
        {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_PIPELINE_STAGE") }} b
        on b.stage_id = a.deal_pipeline_stage_id
        and b.is_active = 1
    left join
        {{ ref("hubspot_dim_stage_mapping") }} dsmm
        on b.label = dsmm.stage_name and dsmm.source_schema = 'HUBSPOT_PAWVILLE'

    )

{% endif %}

, final as (
select
        CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        ID as OPPORTUNITY_ID,
        md5(   
        coalesce(nullif(cast(OWNER_ID as string),''), '') || '|' ||
        'HUBSPOT'
        ) as OWNER_ID,
        STAGE_NAME,
        AMOUNT,
        CLOSE_DATE,
        CAST(IS_CLOSED_N as Boolean) as IS_CLOSED,
        CAST(IS_WON_N as Boolean) as IS_WON,
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
        'HUBSPOT_PAWVILLE'
        ) as OWNER_ID,
        STAGE_NAME,
        AMOUNT,
        CLOSE_DATE,
        CAST(IS_CLOSED_N as Boolean) as IS_CLOSED,
        CAST(IS_WON_N as Boolean) as IS_WON,
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

)

,
base AS (
    SELECT
        *
    FROM final

),
services AS (
    SELECT
        *
    FROM base
)
SELECT 
*, 
row_number() over (partition by opportunity_id, source_schema order by DBT_VALID_FROM) as rank,
FROM services