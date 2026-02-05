with source as (
    select *
    from {{ source('macro_raw', 'ADP_EMPLOYMENT') }}
)

    select
        cast(date as date) as DATE,
        REPLACE(Date,'-','') AS DATEKEY,
        TRIM(timestep)       as TIMESTEP,
        TRIM(category)       as CATEGORY,
        TRIM(agg_RIS)        as AGG_RIS,
        cast(NER  as float)          as NER,
        cast(NER_SA as float)        as NER_SA
    from source