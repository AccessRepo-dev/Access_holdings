with source as (
    select *
    from {{ source('macro_raw', 'ADP_PAYINSIGHTS') }}
)

    select
        cast("date" as date) as DATE,
        REPLACE(Date,'-','') AS DATEKEY,
        TRIM("timestep")       as TIMESTEP,
        TRIM("category")       as CATEGORY,
        TRIM("agg")            as AGG,
        "median pay change" as MEDIAN_PAY_CHANGE,
        "median annual pay" as MEDIAN_ANNUAL_PAY
    from source