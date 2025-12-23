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
    CONCAT(
            COALESCE(
                TRIM(CAST(PROPERTY_LOCATION_ID AS VARCHAR)),
                TRIM(
                    CASE 
                        WHEN PROPERTY_CLUB_C ILIKE '%Lakeview%' THEN '1'
                        WHEN PROPERTY_CLUB_C ILIKE '%Gold Coast%' THEN '2'
                        WHEN PROPERTY_CLUB_C ILIKE '%River North%' THEN '3'
                        WHEN PROPERTY_CLUB_C ILIKE '%Wicker Park%' THEN '4'
                        WHEN PROPERTY_CLUB_C ILIKE '%South Loop%' THEN '5'
                        WHEN PROPERTY_CLUB_C ILIKE '%Streeterville%' THEN '6'
                        WHEN PROPERTY_CLUB_C ILIKE '%Lakeshore East%' THEN '7'
                        WHEN PROPERTY_CLUB_C ILIKE '%DoBro%' THEN '8'
                        WHEN PROPERTY_CLUB_C ILIKE '%Williamsburg%' THEN '9'
                        ELSE NULL
                    END
                )
            ),
            '-pupspetclub'
        ) AS SK_LOCATION_ID,
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
    FIRST_VALUE(sk_location_id) OVER (PARTITION BY contact_id ORDER BY property_hs_projected_amount DESC NULLS LAST, property_closedate) AS lead_sk_location_id,
    MIN(property_createdate) OVER (PARTITION BY contact_id) AS contact_date,
    b.label as STAGE_NAME,
    property_hs_all_owner_ids as OWNER_ID,
    A.property_amount as AMOUNT,
    A.property_closedate as CLOSE_DATE,
    case when a.stage_name ilike 'close%' and a.stage_name ilike '%won' then 1 else 0 end as IS_WON_N,
    case when a.stage_name ilike 'close%' then 1 else 0 end as IS_CLOSED_N,
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
        coalesce(IS_WON::string,'') || '|' ||
        coalesce(IS_CLOSED::string,'')
    ) as attr_hash
from {{ get_silver_source(company, "HUBSPOT_DEAL") }} a
left join {{ get_silver_source(company, "HUBSPOT_DEAL_CONTACT") }} c
on a.DEAL_ID = c.DEAL_ID

left join
    {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE_STAGE") }} b
    on b.stage_id = a.deal_pipeline_stage_id
    and b.is_active = 1

)
{% if company == "wagway" %}

    ,pawville_hashed as (

    select
        A.deal_id as ID,
        PROPERTY_DEALNAME,
        CONTACT_ID,
        CONCAT(TRIM(CAST(PROPERTY_LOCATION_ID AS VARCHAR)), '-pawville') AS SK_LOCATION_ID,
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
        FIRST_VALUE(sk_location_id) OVER (PARTITION BY contact_id ORDER BY property_hs_projected_amount DESC NULLS LAST, property_closedate) AS lead_sk_location_id,
        MIN(property_createdate) OVER (PARTITION BY contact_id) AS contact_date,
        b.label as STAGE_NAME,
        property_hs_all_owner_ids as OWNER_ID,
        A.property_amount as AMOUNT,
        A.property_closedate as CLOSE_DATE,
        case when a.stage_name ilike 'close%' and a.stage_name ilike '%won' then 1 else 0 end as IS_WON_N,
        case when a.stage_name ilike 'close%' then 1 else 0 end as IS_CLOSED_N,
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
            coalesce(IS_WON::string,'') || '|' ||
            coalesce(IS_CLOSED::string,'')
        ) as attr_hash
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a
    left join {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_CONTACT") }} c
    on a.DEAL_ID = c.DEAL_ID
    join
        {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_PIPELINE_STAGE") }} b
        on b.stage_id = a.deal_pipeline_stage_id
        and b.is_active = 1

    )

{% endif %}

, final as (
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
        CAST(IS_CLOSED_N as Boolean) as IS_CLOSED,
        CAST(IS_WON_N as Boolean) as IS_WON,
        PROBABILITY*100 as PROBABILITY,
         CASE 
        WHEN ACQUISITION_DATE IS NOT NULL
            THEN 'Closed Won'
        WHEN SUM(CASE WHEN PROPERTY_HS_IS_CLOSED_LOST = FALSE AND ACQUISITION_DATE IS NULL THEN 1 ELSE 0 END) OVER (PARTITION BY CONTACT_ID) > 0 
            THEN 'Open Lead'
        ELSE 'Closed Lost'
      END AS LEAD_STATUS,
        PROPERTY_DEALNAME,
        CONTACT_ID,
        property_createdate,
        acquisition_date,
        SK_LOCATION_ID,
        lead_sk_location_id,
        contact_date,

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
        CAST(IS_CLOSED_N as Boolean) as IS_CLOSED,
        CAST(IS_WON_N as Boolean) as IS_WON,
        PROBABILITY*100 as PROBABILITY,
     CASE 
        WHEN ACQUISITION_DATE IS NOT NULL
            THEN 'Closed Won'
        WHEN SUM(CASE WHEN PROPERTY_HS_IS_CLOSED_LOST = FALSE AND ACQUISITION_DATE IS NULL THEN 1 ELSE 0 END) OVER (PARTITION BY CONTACT_ID) > 0 
            THEN 'Open Lead'
        ELSE 'Closed Lost'
      END AS LEAD_STATUS,
        PROPERTY_DEALNAME,
        CONTACT_ID,
        property_createdate,
        acquisition_date,
        SK_LOCATION_ID,
        lead_sk_location_id,
        contact_date,

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
        {% if company == 'wagway' %},
        ARRAY_COMPACT(ARRAY_CONSTRUCT(
            CASE WHEN property_dealname ILIKE '%Daycare%' THEN 'Daycare' END,
            CASE WHEN property_dealname ILIKE '%Grooming%' OR property_dealname ILIKE '%Groom%' THEN 'Grooming' END,
            CASE WHEN property_dealname ILIKE '%Training%' THEN 'Training' END,
            CASE WHEN property_dealname ILIKE '%Pet Sitting%' 
                   OR property_dealname ILIKE '%Petsitting%' 
                   OR property_dealname ILIKE '%Pet-Sitting%' THEN 'Pet Sitting' END,
            CASE WHEN property_dealname ILIKE '%Overnights%' 
                   OR property_dealname ILIKE '%Overnight%' THEN 'Overnights' END,
            CASE WHEN property_dealname ILIKE '%Boarding%' THEN 'Boarding' END,
            CASE WHEN property_dealname ILIKE '%Walking%' THEN 'Walking' END,
            CASE WHEN property_dealname ILIKE '%Puppy Play Care%' 
                   OR property_dealname ILIKE '%Puppy Playcare%' THEN 'Puppy Playcare' END,
            CASE WHEN property_dealname ILIKE '%Playcare%' THEN 'Playcare' END,
            CASE WHEN property_dealname ILIKE '%Gingr Sign Up%' THEN 'Gingr Sign Up' END,
            CASE WHEN property_dealname ILIKE '%New Lead%' THEN 'New Lead' END,
            CASE WHEN property_dealname ILIKE '%Membership%' THEN 'Membership' END,
            CASE WHEN property_dealname ILIKE '%Wellness%' 
                   OR property_dealname ILIKE '%WellCare%' 
                   OR property_dealname ILIKE '%Well Care%' THEN 'Wellness' END,
            CASE WHEN property_dealname ILIKE '%Transport%' THEN 'Transport' END,
            CASE WHEN property_dealname ILIKE '%Veterinary%' 
                   OR property_dealname ILIKE '%Vet%' THEN 'Veterinary' END,
            CASE WHEN property_dealname ILIKE '%General%' THEN 'General' END
        )) AS svc_array
    {%endif%}
    FROM final

),
services AS (
    SELECT
        *,
        ARRAY_TO_STRING(ARRAY_DISTINCT(svc_array), ', ') AS GROUPED_SERVICE_TYPE,
        CASE
            WHEN ARRAY_SIZE(svc_array) = 0 THEN NULL
            WHEN LOWER(svc_array[0]::string) IN ('new lead', 'gingr sign up') 
                 AND ARRAY_SIZE(svc_array) > 1 THEN svc_array[1]::string
            ELSE svc_array[0]::string
        END AS SERVICE_TYPE
    FROM base
)
SELECT 
*, 
row_number() over (partition by opportunity_id, source_schema order by DBT_VALID_FROM) as rank,


FROM services


