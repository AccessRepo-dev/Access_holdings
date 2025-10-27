with source as (
    select *
    from {{ source('macro_raw', 'NAHB_HOUSING') }}
),
transformed AS (
    select
    TRIM("month") AS MONTH,
    CAST(TRIM(SPLIT_PART("month",',',2)) AS NUMBER) AS YEAR,
    TRIM(SPLIT_PART("month",' ',1)) AS MONTH_NAME,
    "tr_td" AS HMI --HOUSING MARKET INDEX
from source
)
SELECT 
*,
CAST(CONCAT(CAST(YEAR * 100 + EXTRACT(MONTH FROM TO_DATE(month_name, 'MMMM')), VARCHAR),  '01') AS INT) AS DateKey
FROM transformed

