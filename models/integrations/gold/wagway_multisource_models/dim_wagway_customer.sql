{% set company = var('company') %}

{{ config(
    enabled = (var('company') | lower) == 'wagway',
    database = get_target_database(company),
    materialized = 'table',
    alias = 'DIM_WAGWAY_CUSTOMER'
) }}

WITH cte1 AS (
    SELECT
        COALESCE(
            property_hs_calculated_phone_number,
            property_hs_calculated_mobile_number,
            CONCAT('+1', REGEXP_REPLACE(property_mobilephone, '[^0-9]', '')),
            CONCAT('+1', REGEXP_REPLACE(property_phone, '[^0-9]', ''))
        ) AS phone_number
    FROM {{ get_silver_source('wagway', 'hubspot_contact') }}
    WHERE is_active = 1
 
    UNION ALL
 
    SELECT
        COALESCE(
            property_hs_calculated_phone_number,
            property_hs_calculated_mobile_number,
            CONCAT('+1', REGEXP_REPLACE(property_mobilephone, '[^0-9]', '')),
            CONCAT('+1', REGEXP_REPLACE(property_phone, '[^0-9]', ''))
        ) AS phone_number
    FROM {{ get_silver_source('wagway', 'hubspot_pawville_contact') }}
    WHERE is_active = 1
 
    UNION ALL
 
    SELECT
        CONCAT('+1', REGEXP_REPLACE(cell_phone, '[^0-9]', '')) AS phone_number
    FROM {{ get_silver_source('wagway', 'gingr_owners') }}
    WHERE delete_indicator = 0
 
    UNION ALL
 
    SELECT
        CASE WHEN direction = 'Inbound' THEN from_phone_number ELSE to_phone_number END AS phone_number
    FROM {{ get_silver_source('wagway', 'ringcentral_account_call_log') }}
),
cte2 AS (
    SELECT DISTINCT
        CASE
            WHEN LENGTH(REGEXP_REPLACE(phone_number, '[^0-9]', '')) = 10
                THEN CONCAT('+1', REGEXP_REPLACE(phone_number, '[^0-9]', ''))
            WHEN LENGTH(REGEXP_REPLACE(phone_number, '[^0-9]', '')) = 11
                AND LEFT(REGEXP_REPLACE(phone_number, '[^0-9]', ''), 1) = '1'
                THEN CONCAT('+', REGEXP_REPLACE(phone_number, '[^0-9]', ''))
            ELSE CONCAT('+', REGEXP_REPLACE(phone_number, '[^0-9]', ''))
        END AS phone_number
    FROM cte1
    WHERE phone_number IS NOT NULL
),
cte3 AS (
    SELECT
        a.phone_number,
        COALESCE(
            CONCAT(h.first_name, ' ', h.last_name),
            CONCAT(e.property_firstname, ' ', e.property_lastname),
            CONCAT(b.property_firstname, ' ', b.property_lastname),
            CASE WHEN i.direction = 'Inbound' THEN i.from_name ELSE i.to_name END
        ) AS name,
        COALESCE(
            h.email,
            e.property_email,
            e.property_gingr_email,
            b.property_email,
            b.property_gingr_email
        ) AS email,
        COALESCE(
            h.city,
            e.property_city,
            b.property_city,
            CASE WHEN i.direction = 'Inbound' THEN i.from_location ELSE i.to_location END
        ) AS location,
        COALESCE(
            h.address_1,
            e.property_address,
            b.property_address
        ) AS address
    FROM cte2 a
    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_pawville_contact') }} b
        ON a.phone_number = COALESCE(
            b.property_hs_calculated_phone_number,
            b.property_hs_calculated_mobile_number,
            CONCAT('+1', REGEXP_REPLACE(b.property_mobilephone, '[^0-9]', '')),
            CONCAT('+1', REGEXP_REPLACE(b.property_phone, '[^0-9]', ''))
        )
        AND b.is_active = 1
    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_contact') }} e
        ON a.phone_number = COALESCE(
            e.property_hs_calculated_phone_number,
            e.property_hs_calculated_mobile_number,
            CONCAT('+1', REGEXP_REPLACE(e.property_mobilephone, '[^0-9]', '')),
            CONCAT('+1', REGEXP_REPLACE(e.property_phone, '[^0-9]', ''))
        )
        AND e.is_active = 1
    LEFT JOIN {{ get_silver_source('wagway', 'gingr_owners') }} h
        ON a.phone_number = CONCAT('+1', REGEXP_REPLACE(h.cell_phone, '[^0-9]', ''))
        AND h.delete_indicator = 0
    LEFT JOIN {{ get_silver_source('wagway', 'ringcentral_account_call_log') }} i
        ON a.phone_number = CASE WHEN i.direction = 'Inbound' then i.from_phone_number ELSE i.to_phone_number END
),
cte4 AS (
    SELECT
        phone_number,
        MAX_BY(name, CASE WHEN name IS NOT NULL AND TRIM(name) <> '' THEN 1 ELSE 0 END) AS name,
        MAX_BY(email, CASE WHEN email IS NOT NULL AND TRIM(email) <> '' THEN 1 ELSE 0 END) AS email,
        MAX_BY(location, CASE WHEN location IS NOT NULL AND TRIM(location) <> '' THEN 1 ELSE 0 END) AS location,
        MAX_BY(address, CASE WHEN address IS NOT NULL AND TRIM(address) <> '' THEN 1 ELSE 0 END) AS address
    FROM cte3
    WHERE phone_number IS NOT NULL
    GROUP BY phone_number
)
SELECT 
    PHONE_NUMBER,
    COALESCE(NAME,PHONE_NUMBER) AS NAME,
    EMAIL,
    LOCATION,
    ADDRESS,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS LAST_REFRESH_DATE
FROM cte4
WHERE LENGTH(phone_number) > 8
