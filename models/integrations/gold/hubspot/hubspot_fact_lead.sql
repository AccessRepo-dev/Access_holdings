SELECT
        sl.HS_LEAD_ID,
        o.owner_key,
        c.company_key,
        sl.status,
        sl.source,
        dd1.date_key AS created_date_key,
        dd2.date_key AS modified_date_key,
        dd3.date_key AS converted_date_key,
        CASE WHEN sl.status = 'Converted' THEN TRUE ELSE FALSE END AS is_converted,
        CURRENT_TIMESTAMP() AS gold_load_date
   select *  FROM HUBSPOT_DB.SILVER.LEAD sl
    LEFT JOIN HUBSPOT_DB.GOLD.DIM_OWNER o
           ON sl.lead_owner_id = o.hs_owner_id AND o.is_current = TRUE
    LEFT JOIN HUBSPOT_DB.GOLD.DIM_COMPANY c
           ON sl.DATE_VALUE = c.hs_company_id AND c.is_current = TRUE
    LEFT JOIN HUBSPOT_DB.GOLD.DIM_DATE dd1 
           ON dd1.DATE_VALUE = CAST(sl.created_date AS DATE)
    LEFT JOIN HUBSPOT_DB.GOLD.DIM_DATE dd2 
           ON dd2.DATE_VALUE = CAST(sl.modified_date AS DATE)
    LEFT JOIN HUBSPOT_DB.GOLD.DIM_DATE dd3 
           ON dd3.DATE_VALUE = CAST(sl.modified_date AS DATE)
