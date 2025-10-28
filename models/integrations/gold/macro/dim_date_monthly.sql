WITH months AS (
    SELECT
        DATEADD(
            month,
            SEQ4(),
            TO_DATE('2000-01-01', 'YYYY-MM-DD')
        ) AS first_day
    FROM TABLE(GENERATOR(ROWCOUNT => 612))  -- 51 years * 12 months = 612 rows
)
SELECT
    first_day AS FULL_DATE,
    CAST(TO_VARCHAR(first_day, 'YYYYMMDD') AS INT) AS DATEKEY,     -- e.g. 202410
    TO_VARCHAR(first_day, 'YYYY-MM') AS YEAR_MONTH,              -- e.g. 2024-10
    YEAR(first_day) AS YEAR,
    MONTH(first_day) AS MONTH,
    TO_VARCHAR(first_day, 'Mon') AS MONTH_SHORT_NAME,            -- Jan, Feb, ...
    TO_VARCHAR(first_day, 'Month') AS MONTH_FULL_NAME,           -- January, February, ...
    QUARTER(first_day) AS QUARTER,
    'Q' || QUARTER(first_day) AS QUARTER_NAME,
    LAST_DAY(first_day) AS MONTH_END_DATE
FROM months
WHERE first_day BETWEEN '2000-01-01' AND '2050-12-01'
  AND DAY(first_day) = 1    