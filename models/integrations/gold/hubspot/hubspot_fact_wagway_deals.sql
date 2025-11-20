{% set company = var('company') %}

{{ config(
    enabled = (var('company') | lower) == 'wagway',
    database = get_target_database(company),
    materialized = 'table',
    alias = 'FACT_WAGWAY_HUBSPOT_DEALS'
) }}

WITH cte AS (

    -- Pawville HubSpot Deals (active only)
    SELECT 
        DEAL_ID,
        PROPERTY_DEALNAME,
        PROPERTY_AMOUNT,
        DEAL_PIPELINE_ID,
        DEAL_PIPELINE_STAGE_ID,
        PROPERTY_HS_IS_CLOSED_WON,
        PROPERTY_CLOSEDATE,
        PROPERTY_CREATEDATE,
        PROPERTY_HS_CREATEDATE,
        OWNER_ID,
        PROPERTY_HS_ALL_OWNER_IDS,
        PROPERTY_DEALTYPE,
        PROPERTY_HS_FORECAST_AMOUNT,
        PROPERTY_HS_DEAL_STAGE_PROBABILITY,
        PROPERTY_DESCRIPTION,
        CONCAT(TRIM(CAST(PROPERTY_LOCATION_ID AS VARCHAR)), '-pawville') AS SK_LOCATION_ID,
        NULL AS SERVICE_CATEGORY,
        PROPERTY_HS_PROJECTED_AMOUNT,
        CONCAT(CAST(PROPERTY_INVOICE_ID AS VARCHAR), '-pawville') AS PROPERTY_INVOICE_ID,
        'Pawville' AS COMPANY,
        IS_ACTIVE
    FROM {{ get_silver_source('wagway', 'hubspot_pawville_deal') }}
    WHERE IS_ACTIVE = 1

    UNION ALL

    -- PUPS HubSpot Deals (active only)
    SELECT 
        DEAL_ID,
        PROPERTY_DEALNAME,
        PROPERTY_AMOUNT,
        DEAL_PIPELINE_ID,
        DEAL_PIPELINE_STAGE_ID,
        PROPERTY_HS_IS_CLOSED_WON,
        PROPERTY_CLOSEDATE,
        PROPERTY_CREATEDATE,
        PROPERTY_HS_CREATEDATE,
        OWNER_ID,
        PROPERTY_HS_ALL_OWNER_IDS,
        PROPERTY_DEALTYPE,
        PROPERTY_HS_FORECAST_AMOUNT,
        PROPERTY_HS_DEAL_STAGE_PROBABILITY,
        PROPERTY_DESCRIPTION,
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
            WHEN PROPERTY_SERVICE_TYPE ILIKE '%,%' THEN 'Bundled Service'
            ELSE PROPERTY_SERVICE_TYPE
        END AS SERVICE_CATEGORY,
        PROPERTY_HS_PROJECTED_AMOUNT,
        CONCAT(CAST(PROPERTY_INVOICE_ID AS VARCHAR), '-pupspetclub') AS PROPERTY_INVOICE_ID,
        'PUPS Pet Club' AS COMPANY,
        IS_ACTIVE
    FROM {{ get_silver_source('wagway', 'hubspot_deal') }}
    WHERE IS_ACTIVE = 1
),

base AS (
    SELECT *,
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
    FROM cte
),

services AS (
    SELECT
        *,
        ARRAY_TO_STRING(ARRAY_DISTINCT(svc_array), ', ') AS GROUPED_SERVICE_TYPE,
        CASE
            WHEN ARRAY_SIZE(svc_array) = 0 THEN NULL
            WHEN LOWER(svc_array[0]::string) IN ('new lead', 'gingr sign up') 
                 AND ARRAY_SIZE(svc_array) > 1
                THEN svc_array[1]::string
            ELSE svc_array[0]::string
        END AS SERVICE_TYPE
    FROM base
),

final_enriched AS (
    SELECT
        f.deal_id,
        f.property_dealname,
        b.contact_id,

        -- transaction total into first row only; default 0
        NVL(
            CASE 
                WHEN ROW_NUMBER() OVER (PARTITION BY f.deal_id ORDER BY ac.code) = 1 
                    THEN CAST(COALESCE(t.total, f.property_amount) AS FLOAT)
                ELSE 0
            END,
        0) AS property_amount,

        f.deal_pipeline_id,
        f.deal_pipeline_stage_id,
        f.property_hs_is_closed_won,
        f.property_closedate,
        CASE WHEN f.property_createdate > f.property_closedate 
            THEN f.property_closedate 
            ELSE f.property_createdate END AS property_createdate,
        f.owner_id,

        -- PHONE NUMBER PRIORITY
        COALESCE(
            c.property_hs_calculated_phone_number,
            c.property_hs_calculated_mobile_number,
            e.property_hs_calculated_phone_number,
            e.property_hs_calculated_mobile_number,
            CONCAT('+1', REGEXP_REPLACE(c.property_mobilephone, '[^0-9]', '')),
            CONCAT('+1', REGEXP_REPLACE(c.property_phone, '[^0-9]', '')),
            CONCAT('+1', REGEXP_REPLACE(j.cell_phone, '[^0-9]', '')),
            CONCAT('+1', REGEXP_REPLACE(e.property_mobilephone, '[^0-9]', '')),
            CONCAT('+1', REGEXP_REPLACE(e.property_phone, '[^0-9]', ''))
        ) AS phone_number,

        f.property_hs_all_owner_ids,
        f.property_dealtype,
        f.property_hs_forecast_amount,
        f.property_hs_deal_stage_probability,
        f.property_description,
        f.sk_location_id,
        COALESCE(f.service_category, f.service_type) AS service_category,
        f.property_hs_projected_amount,
        f.property_invoice_id,
        f.company,

        -- enhanced service_type logic (packages, memberships, pipe parsing)
        COALESCE(
            CASE 
                WHEN f.service_type IS NULL AND f.property_invoice_id IS NOT NULL 
                    THEN (
                        CASE 
                            WHEN ac.code ILIKE '%packages %' 
                                THEN RIGHT(ac.code, LENGTH(ac.code) - POSITION('|' , ac.code) - 1)
                            WHEN ac.code ILIKE '%memberships%' 
                                THEN 'Memberships'
                            WHEN ac.code ILIKE '%|%' 
                                THEN LEFT(ac.code, POSITION('|' , ac.code) - 2)
                            ELSE ac.code
                        END
                    )
                WHEN f.service_type IS NULL AND f.property_invoice_id IS NULL 
                    THEN 'Other deal'
                ELSE f.service_type 
            END,
        'Invoiced') AS service_type,

        f.grouped_service_type

    FROM services AS f

    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_deal_contact') }} b 
        ON f.deal_id = b.deal_id

    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_contact') }} c 
        ON c.id = b.contact_id

    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_pawville_deal_contact') }} d 
        ON f.deal_id = d.deal_id

    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_pawville_contact') }} e 
        ON e.id = d.contact_id

    -- join transactions by concatenated invoice id + source_db (matches PROPERTY_INVOICE_ID with suffix)
    LEFT JOIN {{ get_silver_source('wagway', 'gingr_pos_transactions') }} t 
        ON CONCAT(t.id, '-', t.source_db) = f.property_invoice_id

    LEFT JOIN {{ get_silver_source('wagway', 'gingr_owners') }} j 
        ON j.id = t.owner_id

    LEFT JOIN {{ get_silver_source('wagway', 'gingr_pos_transaction_items_audit') }}  tia 
        ON tia.pos_transaction_id = t.id

    LEFT JOIN {{ get_silver_source('wagway', 'gingr_account_codes') }} ac 
        ON ac.id = tia.account_code_id
)

SELECT DISTINCT * FROM final_enriched
