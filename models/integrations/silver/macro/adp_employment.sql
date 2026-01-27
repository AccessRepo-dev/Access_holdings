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
        "NER"            as NER,
        "NER_SA"         as NER_SA
    from source