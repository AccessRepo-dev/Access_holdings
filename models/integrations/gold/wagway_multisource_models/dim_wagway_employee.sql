{{ config(
    database = get_target_database('wagway'),
    materialized = 'table',
    alias = 'DIM_WAGWAY_EMPLOYEE'
) }}

WITH email_all AS (
    SELECT DISTINCT email
    FROM {{ get_silver_source('wagway', 'ringcentral_company_directory') }}

    UNION

    SELECT DISTINCT email
    FROM  {{ get_silver_source('wagway', 'hubspot_owner') }}
    WHERE is_active = 1

    UNION 

    SELECT DISTINCT email
    FROM {{ get_silver_source('wagway', 'hubspot_pawville_owner') }}
    WHERE is_active = 1
)

SELECT DISTINCT
      ded.email AS emp_email,
      COALESCE(hbs.owner_id, hbpw.owner_id) AS hubspot_emp_id,
      rng.id AS rng_emp_id,
      COALESCE(
          CONCAT(rng.first_name, ' ', rng.last_name),
          rng.name,
          CONCAT(hbs.first_name, ' ', hbs.last_name),
          CONCAT(hbpw.first_name, ' ', hbpw.last_name)
      ) AS emp_name,
      COALESCE(
          hbs_tm.name,
          -- hbpw_tm.name,
          rng.department
      ) AS emp_department,
      rng.id AS emp_extension_id,
      rng_phn.phone_number AS emp_phone_number,
      rng.site_name AS emp_location,
      CONVERT_TIMEZONE('Asia/Kolkata', CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS LAST_REFRESH_DATE

FROM email_all ded

LEFT JOIN {{ get_silver_source('wagway', 'ringcentral_company_directory') }} rng
    ON ded.email = rng.email

LEFT JOIN {{ get_silver_source('wagway', 'ringcentral_company_directory_phone_number') }} rng_phn
    ON rng.id = rng_phn.company_directory_id

LEFT JOIN {{ get_silver_source('wagway', 'hubspot_owner') }} hbs
    ON ded.email = hbs.email
   AND hbs.is_active = 1

LEFT JOIN {{ get_silver_source('wagway', 'hubspot_deal') }}  hbs_dl
    ON hbs.owner_id = hbs_dl.owner_id
   AND hbs_dl.is_active = 1

LEFT JOIN {{ get_silver_source('wagway', 'hubspot_owner_team') }}  hbs_otm
    ON hbs.owner_id = hbs_otm.owner_id
   AND hbs_otm.is_active = 1

LEFT JOIN {{ get_silver_source('wagway', 'hubspot_team') }} hbs_tm
    ON hbs_otm.team_id = hbs_tm.id
   AND hbs_tm.is_active = 1

LEFT JOIN {{ get_silver_source('wagway', 'hubspot_pawville_owner') }}  hbpw
    ON ded.email = hbpw.email
   AND hbpw.is_active = 1

LEFT JOIN {{ get_silver_source('wagway', 'hubspot_pawville_deal') }} hbpw_dl
    ON hbpw.owner_id = hbpw_dl.owner_id
   AND hbpw_dl.is_active = 1
