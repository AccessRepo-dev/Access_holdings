-- {% set company = var('company', 'Unknown company') | lower %}
-- {% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
-- {{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}
select
    *
from {{source('wagway_silver','NETSUIT_ACCOUNTINGPERIOD')}} 
