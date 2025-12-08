{{ config(
    database = get_target_database('wagway'),
    materialized = 'table',
    alias = 'FACT_RINGCENTRAL'
) }}

----------------------------------------------------------
-- CTE1: Gingr owners → clean phone numbers + acquisition
----------------------------------------------------------

WITH cte1 AS (
    SELECT DISTINCT
        CASE
            WHEN LENGTH(
                REGEXP_REPLACE(CONCAT('+1', REGEXP_REPLACE(a.cell_phone, '[^0-9]', '')), '[^0-9]', '')
            ) = 10 THEN CONCAT(
                '+1',
                REGEXP_REPLACE(CONCAT('+1', REGEXP_REPLACE(a.cell_phone, '[^0-9]', '')), '[^0-9]', '')
            )

            WHEN LENGTH(
                REGEXP_REPLACE(CONCAT('+1', REGEXP_REPLACE(a.cell_phone, '[^0-9]', '')), '[^0-9]', '')
            ) = 11
             AND LEFT(
                    REGEXP_REPLACE(CONCAT('+1', REGEXP_REPLACE(a.cell_phone, '[^0-9]', '')), '[^0-9]', ''),
                    1
                ) = '1'
                THEN CONCAT(
                    '+',
                    REGEXP_REPLACE(CONCAT('+1', REGEXP_REPLACE(a.cell_phone, '[^0-9]', '')), '[^0-9]', '')
                )

            ELSE CONCAT(
                '+',
                REGEXP_REPLACE(CONCAT('+1', REGEXP_REPLACE(a.cell_phone, '[^0-9]', '')), '[^0-9]', '')
            )
        END AS clean_number,
        a.id AS owner_id,
        MIN(b.create_stamp) OVER (PARTITION BY b.owner_id) AS acquisition_date
    FROM {{ get_silver_source('wagway', 'gingr_owners') }} a
    INNER JOIN {{ get_silver_source('wagway', 'gingr_pos_transactions') }} b
        ON a.id = b.owner_id
    WHERE b.delete_indicator = 0
),

----------------------------------------------------------
-- CTE2: Main Call Log with company directory + hubspot + gingr match
----------------------------------------------------------

cte2 AS (
    SELECT DISTINCT
        a.id,
        a.start_time,
        DAYNAME(a.start_time) AS week_day,
        a.duration,
        a.duration_ms,
        a.type,
        a.internal_type,
        a.direction,
        a.action,
        a.result,
        a.reason,
        a.reason_description,
        a.account_id,
        a.session_id,
        br."FROM" AS time_from,
        br."TO" AS time_to,

        a.from_phone_number,
        a.from_extension_number,
        a.from_extension_id,
        a.from_location,
        a.from_name,
        a.from_dialed_phone_number,

        a.to_phone_number,
        a.to_extension_number,
        a.to_extension_id,
        a.to_location,
        a.to_name,
        a.to_dialed_phone_number,

        a.extension_id,

        COALESCE(a.from_extension_id, cpn.company_directory_id) AS employee_extension_id,

        'PUPS Pet Club' AS company,

        CASE
            WHEN a.direction = 'Inbound' THEN a.from_phone_number
            ELSE a.to_phone_number
        END AS property_phone_number,

        COALESCE(
            CASE WHEN a.direction = 'Outbound' THEN a.from_name ELSE a.to_name END,
            CONCAT(c.first_name, ' ', c.last_name)
        ) AS location,

        CASE
            WHEN a.direction = 'Inbound' THEN a.from_name
            ELSE a.to_name
        END AS property,

        a.duration_ms / 360000.0 AS hours,

        CASE
            WHEN a.direction = 'Inbound'
             AND a.result = 'Missed'
             AND NOT EXISTS (
                    SELECT 1
                    FROM {{ get_silver_source('wagway', 'ringcentral_account_call_log') }} b
                    WHERE from_phone_number = b.to_phone_number
                      AND b.start_time > a.start_time
                )
            THEN 0 ELSE 1
        END AS callback,

        CASE
            WHEN (
                a.to_name ILIKE '%fwd%'
                OR a.from_name ILIKE '%fwd%'
                OR (
                    a.direction = 'Inbound'
                    AND a.from_phone_number IS NULL
                    AND REPLACE(from_name, ' ', '') IN (
                        SELECT REPLACE(CONCAT(first_name, last_name), ' ', '')
                        FROM {{ get_silver_source('wagway', 'ringcentral_company_directory') }}
                    )
                )
                OR (
                    a.direction = 'Outbound'
                    AND a.to_phone_number IS NULL
                    AND REPLACE(a.to_name, ' ', '') IN (
                        SELECT REPLACE(CONCAT(first_name, last_name), ' ', '')
                        FROM {{ get_silver_source('wagway', 'ringcentral_company_directory') }}
                    )
                )
            )
            THEN 1 ELSE 0
        END AS forwarded,

        MIN(e.property_club_c) OVER (
            PARTITION BY property_phone_number
            ORDER BY f.property_createdate
        ) AS property_club_c,

        g.owner_id AS customer_id,
        g.acquisition_date,

        CASE
            WHEN DATE(g.acquisition_date) = DATE(a.start_time) THEN 'New Customer'
            WHEN DATE(g.acquisition_date) < DATE(a.start_time) THEN 'Existing Customer'
            ELSE NULL
        END AS new_customer_flag,

        RANK() OVER (PARTITION BY a.id ORDER BY g.acquisition_date DESC) AS rnk

    FROM {{ get_silver_source('wagway', 'ringcentral_account_call_log') }} a

    LEFT JOIN {{ get_silver_source('wagway', 'ringcentral_company_directory_phone_number') }} d
        ON d.phone_number =
            CASE WHEN a.direction = 'Outbound' THEN a.from_phone_number ELSE a.to_phone_number END  

    LEFT JOIN {{ get_silver_source('wagway', 'ringcentral_company_directory') }} c
        ON c.id = d.company_directory_id

    LEFT JOIN {{ get_silver_source('wagway', 'ringcentral_company_directory_phone_number') }} cpn
        ON CASE WHEN a.direction = 'Inbound' THEN a.to_phone_number ELSE a.from_phone_number END = cpn.phone_number

    LEFT JOIN {{ get_silver_source('wagway', 'ringcentral_user_business_hour_range') }} br
        ON employee_extension_id = br.extension_id
       AND week_day = LEFT(UPPER(br.day), 3)

    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_contact') }} e
        ON COALESCE(e.property_hs_calculated_phone_number, e.property_hs_calculated_mobile_number) =
           CASE WHEN a.direction = 'Outbound' THEN a.to_phone_number ELSE a.from_phone_number END
       AND e.is_active = 1

    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_deal_contact') }} b
        ON e.id = b.contact_id
       AND b.is_active = 1

    LEFT JOIN {{ get_silver_source('wagway', 'hubspot_deal') }} f
        ON b.deal_id = f.deal_id
       AND f.is_active = 1

    LEFT JOIN cte1 g
        ON property_phone_number = g.clean_number
)

----------------------------------------------------------
-- FINAL OUTPUT (duplicate-safe)
----------------------------------------------------------

SELECT DISTINCT
    a.*
    EXCLUDE (rnk),

    CASE WHEN a.customer_id IS NOT NULL THEN 1 ELSE 0 END AS is_in_gingr,

    /* ---- 7-day revenue ---- */
    (
        SELECT COALESCE(SUM(g.price), 0)
        FROM {{ get_silver_source('wagway', 'gingr_pos_transactions') }} h
        LEFT JOIN {{ get_silver_source('wagway', 'gingr_pos_transaction_items') }} g
            ON h.id = g.pos_transaction_id
           AND g.delete_indicator = 0
        WHERE a.customer_id = h.owner_id
          AND TO_TIMESTAMP(h.create_stamp) >= a.start_time
          AND TO_TIMESTAMP(h.create_stamp) <= DATEADD(day, 7, a.start_time)
          AND h.delete_indicator = 0
    ) AS revenue_from_gingr_7,

    /* ---- 7-day distinct transactions ---- */
    (
        SELECT COUNT(DISTINCT pos_transaction_id)
        FROM {{ get_silver_source('wagway', 'gingr_pos_transactions') }} h
        LEFT JOIN {{ get_silver_source('wagway', 'gingr_pos_transaction_items') }} g
            ON h.id = g.pos_transaction_id
           AND g.delete_indicator = 0
        WHERE a.customer_id = h.owner_id
          AND TO_TIMESTAMP(h.create_stamp) >= a.start_time
          AND TO_TIMESTAMP(h.create_stamp) <= DATEADD(day, 7, a.start_time)
          AND h.delete_indicator = 0
    ) AS transaction_from_gingr_7,

    /* ---- 7-day distinct services ---- */
    (
        SELECT COUNT(DISTINCT account_code_id)
        FROM {{ get_silver_source('wagway', 'gingr_pos_transactions') }} h
        LEFT JOIN {{ get_silver_source('wagway', 'gingr_pos_transaction_items') }} g
            ON h.id = g.pos_transaction_id
           AND g.delete_indicator = 0
        WHERE a.customer_id = h.owner_id
          AND TO_TIMESTAMP(h.create_stamp) >= a.start_time
          AND TO_TIMESTAMP(h.create_stamp) <= DATEADD(day, 7, a.start_time)
          AND h.delete_indicator = 0
    ) AS service_cnt_gingr_nxt_7days

FROM cte2 a
WHERE rnk = 1