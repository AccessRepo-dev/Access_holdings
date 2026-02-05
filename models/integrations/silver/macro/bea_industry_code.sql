with source as (
    select *
    from {{ source('macro_raw', 'BEA_INDUSTRY_CODE') }}
)

select
    TRIM(Key) as KEY,
    TRIM(Desc) as DESCRIPTION
from source