{% set company = var('company') %}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'FACT_WAGWAY_HUBSPOT_DEALS'
) }}
WITH cte AS (

    -- Pawville HubSpot Deals
    SELECT 
        DEAL_ID,
        PROPERTY_DEALNAME,
        PROPERTY_AMOUNT,
        DEAL_PIPELINE_ID,
        DEAL_PIPELINE_STAGE_ID,
        PROPERTY_CLOSEDATE,
        PROPERTY_CREATEDATE,
        PROPERTY_HS_CREATEDATE,
        PROPERTY_HS_LASTMODIFIEDDATE,
        OWNER_ID,
        PROPERTY_HS_ALL_OWNER_IDS,
        PROPERTY_DEALTYPE,
        PROPERTY_HS_FORECAST_AMOUNT,
        PROPERTY_HS_DEAL_STAGE_PROBABILITY,
        PROPERTY_DESCRIPTION,
        CONCAT(TRIM(PROPERTY_LOCATION_ID), '-pawville') AS SK_LOCATION_ID,
        NULL AS SERVICE_CATEGORY,
        PROPERTY_HS_PROJECTED_AMOUNT,
        PROPERTY_INVOICE_ID,
        'Pawville' AS COMPANY
    FROM {{ get_silver_source('wagway', 'hubspot_pawville_deal') }} 

    UNION ALL

    -- PUPS HubSpot Deals
    SELECT 
        DEAL_ID,
        PROPERTY_DEALNAME,
        PROPERTY_AMOUNT,
        DEAL_PIPELINE_ID,
        DEAL_PIPELINE_STAGE_ID,
        PROPERTY_CLOSEDATE,
        PROPERTY_CREATEDATE,
        PROPERTY_HS_CREATEDATE,
        PROPERTY_HS_LASTMODIFIEDDATE,
        OWNER_ID,
        PROPERTY_HS_ALL_OWNER_IDS,
        PROPERTY_DEALTYPE,
        PROPERTY_HS_FORECAST_AMOUNT,
        PROPERTY_HS_DEAL_STAGE_PROBABILITY,
        PROPERTY_DESCRIPTION,
        CONCAT(
            TRIM(CASE 
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
            END),
            '-pupspetclub'
        ) AS SK_LOCATION_ID,
        CASE 
            WHEN PROPERTY_SERVICE_TYPE ILIKE '%,%' THEN 'Bundled Service'
            ELSE PROPERTY_SERVICE_TYPE
        END AS SERVICE_CATEGORY,
        PROPERTY_HS_PROJECTED_AMOUNT,
        PROPERTY_INVOICE_ID,
        'PUPS Pet Club' AS COMPANY
    FROM {{ get_silver_source('wagway', 'hubspot_deal') }} 
),

base AS (
    SELECT *,
        ARRAY_COMPACT(ARRAY_CONSTRUCT(
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Daycare%' THEN 'Daycare' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Grooming%' OR PROPERTY_DEALNAME ILIKE '%Groom%' THEN 'Grooming' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Training%' THEN 'Training' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Pet Sitting%' OR PROPERTY_DEALNAME ILIKE '%Petsitting%' OR PROPERTY_DEALNAME ILIKE '%Pet-Sitting%' THEN 'Pet Sitting' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Overnights%' OR PROPERTY_DEALNAME ILIKE '%Overnight%' THEN 'Overnights' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Boarding%' THEN 'Boarding' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Walking%' THEN 'Walking' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Puppy Play Care%' OR PROPERTY_DEALNAME ILIKE '%Puppy Playcare%' THEN 'Puppy Playcare' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Playcare%' THEN 'Playcare' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Gingr Sign Up%' THEN 'Gingr Sign Up' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%New Lead%' THEN 'New Lead' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Membership%' THEN 'Membership' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Wellness%' OR PROPERTY_DEALNAME ILIKE '%WellCare%' OR PROPERTY_DEALNAME ILIKE '%Well Care%' THEN 'Wellness' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Transport%' THEN 'Transport' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%Veterinary%' OR PROPERTY_DEALNAME ILIKE '%Vet%' THEN 'Veterinary' END,
            CASE WHEN PROPERTY_DEALNAME ILIKE '%General%' THEN 'General' END
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

final AS (
    SELECT
        f.deal_id,
        f.property_dealname,

        -- pull transaction total into first row only
        CASE WHEN ROW_NUMBER() OVER (PARTITION BY f.deal_id ORDER BY ac.code) = 1
             THEN CAST(COALESCE(t.total, f.property_amount) AS FLOAT)
             ELSE 0 
        END AS property_amount,

        f.deal_pipeline_id,
        f.deal_pipeline_stage_id,
        f.property_closedate,
        CASE WHEN f.property_createdate > f.property_closedate 
             THEN f.property_closedate 
             ELSE f.property_createdate 
        END AS property_createdate,
        f.property_hs_lastmodifieddate,
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

        -- service_type logic
        COALESCE(
            CASE 
                WHEN f.service_type IS NULL AND f.property_invoice_id IS NOT NULL THEN ac.code
                WHEN f.service_type IS NULL AND f.property_invoice_id IS NULL THEN 'Other deal'
                ELSE f.service_type 
            END,
            'Invoiced'
        ) AS service_type,

        f.grouped_service_type

    FROM services f
    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_deal_contact') }} b 
        ON f.deal_id = b.deal_id
    LEFT JOIN  {{ get_silver_source('wagway', 'hubspot_contact') }}  c 
        ON c.id = b.contact_id

    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_pawville_deal_contact') }} d 
        ON f.deal_id = d.deal_id
    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_pawville_contact') }} e 
        ON e.id = d.contact_id

    LEFT JOIN {{ get_silver_source('wagway', 'gingr_pos_transactions') }} t 
        ON CAST(t.id AS NUMBER) = CAST(f.property_invoice_id AS NUMBER)

    LEFT JOIN {{ get_silver_source('wagway', 'gingr_owners') }} j 
        ON j.id = t.owner_id

    LEFT JOIN {{ get_silver_source('wagway', 'gingr_pos_transaction_items_audit') }}  tia 
        ON tia.pos_transaction_id = t.id

    LEFT JOIN {{ get_silver_source('wagway', 'gingr_account_codes') }} ac 
        ON ac.id = tia.account_code_id
)

SELECT * FROM final
