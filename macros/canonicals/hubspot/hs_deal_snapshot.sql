{% macro hs_canonical_deal(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'DEAL_ID',
        'PROPERTY_DEALNAME',
        'PROPERTY_LOCATION_ID',
        'PROPERTY_PRODUCT_GROUP',
        'PROPERTY_AMOUNT',
        'DEAL_PIPELINE_ID',
        'DEAL_PIPELINE_STAGE_ID',
        'PROPERTY_CLOSEDATE',
        'PROPERTY_CREATEDATE',
        'PROPERTY_HS_CREATEDATE',
        'PROPERTY_HS_LASTMODIFIEDDATE',
        'OWNER_ID',
        'PROPERTY_HS_ALL_OWNER_IDS',
        'PROPERTY_DEALTYPE',
        'PROPERTY_HS_FORECAST_AMOUNT',
        'PROPERTY_HS_DEAL_STAGE_PROBABILITY',
        'PROPERTY_SERVICE_REQUEST',
        'PROPERTY_PROPERTY_SOURCE',
        'PROPERTY_DESCRIPTION',
        'PROPERTY_HS_IS_CLOSED_WON',
        'PROPERTY_HS_IS_CLOSED_LOST',
        'PROPERTY_CLUB_C',
        'PROPERTY_SERVICE_TYPE',
        'PROPERTY_SERVICE_CATEGORY',
        'PROPERTY_HS_ANALYTICS_SOURCE',
        'PROPERTY_HS_PROJECTED_AMOUNT',
        'PROPERTY_INVOICE_ID',
        'PROPERTY_CLOSED_LOST_REASON'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'DEAL_ID': 'NUMBER'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'hubspot': {
    'wagway': {
        'DEAL_ID'                             : 'DEAL_ID',
        'PROPERTY_DEALNAME'                  : 'PROPERTY_DEALNAME',
        'PROPERTY_LOCATION_ID'               : 'PROPERTY_LOCATION_ID',
        'PROPERTY_AMOUNT'                    : 'PROPERTY_AMOUNT',
        'DEAL_PIPELINE_ID'                   : 'DEAL_PIPELINE_ID',
        'DEAL_PIPELINE_STAGE_ID'             : 'DEAL_PIPELINE_STAGE_ID',
        'PROPERTY_CLOSEDATE'                 : 'PROPERTY_CLOSEDATE',
        'PROPERTY_CREATEDATE'                : 'PROPERTY_CREATEDATE',
        'PROPERTY_HS_CREATEDATE'             : 'PROPERTY_HS_CREATEDATE',
        'PROPERTY_HS_LASTMODIFIEDDATE'       : 'PROPERTY_HS_LASTMODIFIEDDATE',
        'OWNER_ID'                           : 'OWNER_ID',
        'PROPERTY_HS_ALL_OWNER_IDS'           : 'PROPERTY_HS_ALL_OWNER_IDS',
        'PROPERTY_DEALTYPE'                  : 'PROPERTY_DEALTYPE',
        'PROPERTY_HS_FORECAST_AMOUNT'        : 'PROPERTY_HS_FORECAST_AMOUNT',
        'PROPERTY_HS_DEAL_STAGE_PROBABILITY' : 'PROPERTY_HS_DEAL_STAGE_PROBABILITY',
        'PROPERTY_DESCRIPTION'               : 'PROPERTY_DESCRIPTION',
        'PROPERTY_HS_IS_CLOSED_WON'           : 'PROPERTY_HS_IS_CLOSED_WON',
        'PROPERTY_HS_IS_CLOSED_LOST'          : 'PROPERTY_HS_IS_CLOSED_LOST',
        'PROPERTY_CLUB_C'                    : 'PROPERTY_CLUB_C',
        'PROPERTY_SERVICE_TYPE'              : 'PROPERTY_SERVICE_TYPE',
        'PROPERTY_SERVICE_CATEGORY'          : 'PROPERTY_SERVICE_CATEGORY',
        'PROPERTY_HS_ANALYTICS_SOURCE'        : 'PROPERTY_HS_ANALYTICS_SOURCE',
        'PROPERTY_HS_PROJECTED_AMOUNT'       : 'PROPERTY_HS_PROJECTED_AMOUNT',
        'PROPERTY_INVOICE_ID'                : 'PROPERTY_INVOICE_ID',
        'PROPERTY_CLOSED_LOST_REASON'         : 'PROPERTY_CLOSED_LOST_REASON'
    },

    'amh': {
        'DEAL_ID'                             : 'DEAL_ID',
        'PROPERTY_DEALNAME'                  : 'PROPERTY_DEALNAME',
        'PROPERTY_LOCATION_ID'               : 'PROPERTY_LOCATION_ID',
        'PROPERTY_AMOUNT'                    : 'PROPERTY_AMOUNT',
        'DEAL_PIPELINE_ID'                   : 'DEAL_PIPELINE_ID',
        'DEAL_PIPELINE_STAGE_ID'             : 'DEAL_PIPELINE_STAGE_ID',
        'PROPERTY_CLOSEDATE'                 : 'PROPERTY_CLOSEDATE',
        'PROPERTY_CREATEDATE'                : 'PROPERTY_CREATEDATE',
        'PROPERTY_HS_CREATEDATE'             : 'PROPERTY_HS_CREATEDATE',
        'PROPERTY_HS_LASTMODIFIEDDATE'       : 'PROPERTY_HS_LASTMODIFIEDDATE',
        'OWNER_ID'                           : 'OWNER_ID',
        'PROPERTY_HS_ALL_OWNER_IDS'           : 'PROPERTY_HS_ALL_OWNER_IDS',
        'PROPERTY_DEALTYPE'                  : 'PROPERTY_DEALTYPE',
        'PROPERTY_HS_FORECAST_AMOUNT'        : 'PROPERTY_HS_FORECAST_AMOUNT',
        'PROPERTY_HS_DEAL_STAGE_PROBABILITY' : 'PROPERTY_HS_DEAL_STAGE_PROBABILITY',
        'PROPERTY_SERVICE_REQUEST'            : 'PROPERTY_SERVICE_REQUEST',
        'PROPERTY_PROPERTY_SOURCE'            : 'PROPERTY_PROPERTY_SOURCE',
        'PROPERTY_HS_IS_CLOSED_WON'           : 'PROPERTY_HS_IS_CLOSED_WON',
        'PROPERTY_HS_IS_CLOSED_LOST'          : 'PROPERTY_HS_IS_CLOSED_LOST',
        'PROPERTY_HS_ANALYTICS_SOURCE'        : 'PROPERTY_HS_ANALYTICS_SOURCE',
        'PROPERTY_HS_PROJECTED_AMOUNT'       : 'PROPERTY_HS_PROJECTED_AMOUNT',
        'PROPERTY_CLOSED_LOST_REASON'         : 'PROPERTY_CLOSED_LOST_REASON'
    },

    'playfly': {
        'DEAL_ID'                             : 'DEAL_ID',
        'PROPERTY_DEALNAME'                  : 'PROPERTY_DEALNAME',
        'PROPERTY_PRODUCT_GROUP'             : 'PROPERTY_PRODUCT_GROUP',
        'PROPERTY_AMOUNT'                    : 'PROPERTY_AMOUNT',
        'DEAL_PIPELINE_ID'                   : 'DEAL_PIPELINE_ID',
        'DEAL_PIPELINE_STAGE_ID'             : 'DEAL_PIPELINE_STAGE_ID',
        'PROPERTY_CLOSEDATE'                 : 'PROPERTY_CLOSEDATE',
        'PROPERTY_CREATEDATE'                : 'PROPERTY_CREATEDATE',
        'PROPERTY_HS_CREATEDATE'             : 'PROPERTY_HS_CREATEDATE',
        'PROPERTY_HS_LASTMODIFIEDDATE'       : 'PROPERTY_HS_LASTMODIFIEDDATE',
        'OWNER_ID'                           : 'OWNER_ID',
        'PROPERTY_HS_ALL_OWNER_IDS'           : 'PROPERTY_HS_ALL_OWNER_IDS',
        'PROPERTY_DEALTYPE'                  : 'PROPERTY_DEALTYPE',
        'PROPERTY_HS_FORECAST_AMOUNT'        : 'PROPERTY_HS_FORECAST_AMOUNT',
        'PROPERTY_HS_DEAL_STAGE_PROBABILITY' : 'PROPERTY_HS_DEAL_STAGE_PROBABILITY',
        'PROPERTY_HS_IS_CLOSED_WON'           : 'PROPERTY_HS_IS_CLOSED_WON',
        'PROPERTY_HS_IS_CLOSED_LOST'          : 'PROPERTY_HS_IS_CLOSED_LOST',
        'PROPERTY_HS_ANALYTICS_SOURCE'        : 'PROPERTY_HS_ANALYTICS_SOURCE',
        'PROPERTY_HS_PROJECTED_AMOUNT'       : 'PROPERTY_HS_PROJECTED_AMOUNT',
        'PROPERTY_CLOSED_LOST_REASON'         : 'PROPERTY_CLOSED_LOST_REASON'
    }
  },

  'hubspot_pawville': {
    'wagway': {
       'DEAL_ID'                             : 'DEAL_ID',
        'PROPERTY_DEALNAME'                  : 'PROPERTY_DEALNAME',
        'PROPERTY_LOCATION_ID'               : 'PROPERTY_LOCATION_ID',
        'PROPERTY_AMOUNT'                    : 'PROPERTY_AMOUNT',
        'DEAL_PIPELINE_ID'                   : 'DEAL_PIPELINE_ID',
        'DEAL_PIPELINE_STAGE_ID'             : 'DEAL_PIPELINE_STAGE_ID',
        'PROPERTY_CLOSEDATE'                 : 'PROPERTY_CLOSEDATE',
        'PROPERTY_CREATEDATE'                : 'PROPERTY_CREATEDATE',
        'PROPERTY_HS_CREATEDATE'             : 'PROPERTY_HS_CREATEDATE',
        'PROPERTY_HS_LASTMODIFIEDDATE'       : 'PROPERTY_HS_LASTMODIFIEDDATE',
        'OWNER_ID'                           : 'OWNER_ID',
        'PROPERTY_HS_ALL_OWNER_IDS'           : 'PROPERTY_HS_ALL_OWNER_IDS',
        'PROPERTY_DEALTYPE'                  : 'PROPERTY_DEALTYPE',
        'PROPERTY_HS_FORECAST_AMOUNT'        : 'PROPERTY_HS_FORECAST_AMOUNT',
        'PROPERTY_HS_DEAL_STAGE_PROBABILITY' : 'PROPERTY_HS_DEAL_STAGE_PROBABILITY',
        'PROPERTY_DESCRIPTION'               : 'PROPERTY_DESCRIPTION',
        'PROPERTY_HS_IS_CLOSED_WON'           : 'PROPERTY_HS_IS_CLOSED_WON',
        'PROPERTY_HS_IS_CLOSED_LOST'          : 'PROPERTY_HS_IS_CLOSED_LOST',
        'PROPERTY_HS_ANALYTICS_SOURCE'        : 'PROPERTY_HS_ANALYTICS_SOURCE',
        'PROPERTY_HS_PROJECTED_AMOUNT'       : 'PROPERTY_HS_PROJECTED_AMOUNT',
        'PROPERTY_INVOICE_ID'                : 'PROPERTY_INVOICE_ID',
        'PROPERTY_CLOSED_LOST_REASON'         : 'PROPERTY_CLOSED_LOST_REASON'
    }
  }

} %}

{# -------------------------------
   Validate source
-------------------------------- #}
{# -------------------------------
   Resolve company mapping safely
-------------------------------- #}
{% if source in ['hubspot_pawville', 'hubspot'] %}
  {% set company_mapping = mappings.get(source, {}).get(company, {}) %}
{% else %}
  {# Non-hubspot source → bypass safely #}
  {% set company_mapping = {} %}
{% endif %}


{# -------------------------------
   Generate SELECT list (NULL-safe)
-------------------------------- #}
{% set select_cols = [] %}

{% for col in canonical_cols %}
  {% if col in company_mapping %}
    {% do select_cols.append(company_mapping[col] ~ ' AS ' ~ col) %}
  {% else %}
    {% do select_cols.append(
      'CAST(NULL AS ' ~ column_types.get(col, 'VARCHAR') ~ ') AS ' ~ col
    ) %}
  {% endif %}
{% endfor %}

{{ return(select_cols | join(',\n')) }}

{% endmacro %}
