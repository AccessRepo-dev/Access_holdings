{{ config(
    materialized = "table"
) }}

select
    'wagway' as company,
    *
from {{ source('wagway_dev_silver', 'netsuite_account') }}

union all

select
    'playfly' as company,
    *
from {{ source('playfly_dev_silver', 'netsuite_account') }}
