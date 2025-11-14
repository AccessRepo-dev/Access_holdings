{% set company = var('company') %}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'FACT_WAGWAY_ACCOUNT_CALL_LOG'
) }}

 --config -- mater
SELECT A.ID
    ,A.START_TIME
    ,A.DURATION
    ,A.DURATION_MS
    ,A.TYPE
    ,A.INTERNAL_TYPE
    ,A.DIRECTION
    ,A.ACTION
    ,A.RESULT
    ,A.REASON
    ,A.REASON_DESCRIPTION
    ,A.ACCOUNT_ID
    ,A.SESSION_ID
    ,A.FROM_PHONE_NUMBER
    ,A.FROM_EXTENSION_NUMBER
    ,A.FROM_EXTENSION_ID
    ,A.FROM_LOCATION
    ,A.FROM_NAME
    ,A.FROM_DIALED_PHONE_NUMBER
    ,A.TO_PHONE_NUMBER
    ,A.TO_EXTENSION_NUMBER
    ,A.TO_EXTENSION_ID
    ,A.TO_LOCATION
    ,A.TO_NAME
    ,A.TO_DIALED_PHONE_NUMBER
    ,A.EXTENSION_ID
    ,'PUPS Pet Club' AS COMPANY
    ,CASE
        WHEN A.DIRECTION = 'Inbound'
            THEN A.FROM_PHONE_NUMBER
        ELSE A.TO_PHONE_NUMBER
        END AS PROPERTY_PHONE_NUMBER
    ,COALESCE(CASE
            WHEN A.DIRECTION = 'Outbound'
                THEN A.FROM_NAME
            ELSE A.TO_NAME
            END, CONCAT (
            C.FIRST_NAME
            ,' '
            ,C.LAST_NAME
            )) AS LOCATION
    ,CASE
        WHEN A.DIRECTION = 'Inbound'
            THEN A.FROM_NAME
        ELSE A.TO_NAME
        END AS PROPERTY
    ,A.DURATION_MS / 360000.0 AS HOURS
    ,CASE
        WHEN A.DIRECTION = 'Inbound'
            AND A.result = 'Missed'
            AND NOT EXISTS (
                SELECT 1
                FROM {{ get_silver_source('wagway', 'ringcentral_account_call_log') }} B
                WHERE FROM_PHONE_NUMBER = B.TO_PHONE_NUMBER
                    AND B.START_TIME > START_TIME
                )
            THEN 0
        ELSE 1
        END AS CALLBACK
    ,CASE
        WHEN (
                A.TO_NAME ilike '%fwd%'
                OR A.FROM_NAME ilike '%fwd%'
                OR (
                    (
                        A.DIRECTION = 'Inbound'
                        AND A.FROM_PHONE_NUMBER IS NULL
                        AND replace(FROM_NAME, ' ', '') IN (
                            SELECT replace(CONCAT (
                                        FIRST_NAME
                                        ,LAST_NAME
                                        ), ' ', '')
                            FROM {{ get_silver_source('wagway', 'ringcentral_company_directory') }} 
                            )
                        )
                    OR (
                        A.DIRECTION = 'Outbound'
                        AND A.TO_PHONE_NUMBER IS NULL
                        AND replace(A.TO_NAME, ' ', '') IN (
                            SELECT replace(CONCAT (
                                        FIRST_NAME
                                        ,LAST_NAME
                                        ), ' ', '')
                            FROM {{ get_silver_source('wagway', 'ringcentral_company_directory') }} 
                            )
                        )
                    )
                )
            THEN 1
        ELSE 0
        END AS FORWARDED
    ,E.PROPERTY_CLUB_C
    ,CASE 
		WHEN property_phone_number IN (
				SELECT CASE 
						WHEN LENGTH(REGEXP_REPLACE(CONCAT (
										'+1'
										,REGEXP_REPLACE(cell_phone, '[^0-9]', '')
										), '[^0-9]', '')) = 10
							THEN CONCAT (
									'+1'
									,REGEXP_REPLACE(CONCAT (
											'+1'
											,REGEXP_REPLACE(cell_phone, '[^0-9]', '')
											), '[^0-9]', '')
									)
						WHEN LENGTH(REGEXP_REPLACE(CONCAT (
										'+1'
										,REGEXP_REPLACE(cell_phone, '[^0-9]', '')
										), '[^0-9]', '')) = 11
							AND LEFT(REGEXP_REPLACE(CONCAT (
										'+1'
										,REGEXP_REPLACE(cell_phone, '[^0-9]', '')
										), '[^0-9]', ''), 1) = '1'
							THEN CONCAT (
									'+'
									,REGEXP_REPLACE(CONCAT (
											'+1'
											,REGEXP_REPLACE(cell_phone, '[^0-9]', '')
											), '[^0-9]', '')
									)
						ELSE CONCAT (
								'+'
								,REGEXP_REPLACE(CONCAT (
										'+1'
										,REGEXP_REPLACE(cell_phone, '[^0-9]', '')
										), '[^0-9]', '')
								)
						END
				FROM {{ get_silver_source('wagway', 'gingr_owners') }}
				)
			THEN 1
		ELSE 0
		END AS is_in_gingr
FROM {{ get_silver_source('wagway', 'ringcentral_account_call_log') }} A
LEFT JOIN {{ get_silver_source('wagway', 'ringcentral_company_directory_phone_number') }} D 
    ON D.PHONE_NUMBER = CASE
        WHEN A.DIRECTION = 'Outbound' THEN A.FROM_PHONE_NUMBER
        ELSE A.TO_PHONE_NUMBER
    END
LEFT JOIN {{ get_silver_source('wagway', 'ringcentral_company_directory') }} C 
    ON C.ID = D.COMPANY_DIRECTORY_ID
LEFT JOIN {{ get_silver_source('wagway', 'hubspot_contact') }} E 
    ON COALESCE(E.PROPERTY_HS_CALCULATED_PHONE_NUMBER, E.PROPERTY_HS_CALCULATED_MOBILE_NUMBER) = 
        CASE WHEN A.DIRECTION = 'Outbound' THEN A.TO_PHONE_NUMBER ELSE A.FROM_PHONE_NUMBER END
LEFT JOIN {{ get_silver_source('wagway', 'hubspot_deal_contact') }} B 
    ON E.ID = B.CONTACT_ID
LEFT JOIN {{ get_silver_source('wagway', 'hubspot_deal') }} F 
    ON B.DEAL_ID = F.DEAL_ID
