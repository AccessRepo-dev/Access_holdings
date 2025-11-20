-- {% set company = var('company', 'Unknown company') | lower %}
-- {% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}

-- with cte as (
--     SELECT 

-- e.ACCOUNTKEY AS ACCOUNT_ID, 
-- e.LOCATIONKEY AS LOCATION_ID,
-- e.DEPARTMENTKEY AS DEPARTMENT_ID,
-- e.PROJECTDIMKEY AS PROJECT_ID,
-- e.CLASSDIMKEY AS CLASS_ID,
-- COALESCE(acc.TITLE,E.ACCOUNTTITLE) AS ACCOUNT_NAME,
-- c.NAME AS CLASS_NAME,
-- d.TITLE AS DEPARTMENT_NAME,


