{% macro sf_canonical_opportunity(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'ID',
        'ACCOUNT_ID',
        'OWNER_ID',
        'NAME',
        'STAGE_NAME',
        'AMOUNT',
        'INSTALL_AMOUNT_C',
        'CLOSE_DATE',
        'PROBABILITY',
        'LEAD_SOURCE',
        'CAMPAIGN_ID',
        'FORECAST_CATEGORY_NAME',
        'SYSTEM_SUB_TYPE_C',
        'TOTAL_CONTRACT_VALUE_CURRENCY_C',
        'IS_CLOSED',
        'IS_WON',
        'NEXT_STEP',
        'CREATED_DATE',
        'DESCRIPTION',
        'LOSS_REASON_C',
        'LAST_MODIFIED_DATE'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'ID': 'VARCHAR(18)'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'salesforce': {
    'zeus': {
            'ID'                          : 'ID',
            'ACCOUNT_ID'                  : 'ACCOUNT_ID',
            'OWNER_ID'                    : 'OWNER_ID', 
            'NAME'                        : 'NAME',
            'STAGE_NAME'                  : 'STAGE_NAME',
            'AMOUNT'                      : 'AMOUNT',
            'INSTALL_AMOUNT_C'            : 'INSTALL_AMOUNT_C',
            'CLOSE_DATE'                  : 'CLOSE_DATE',
            'PROBABILITY'                 : 'PROBABILITY',
            'LEAD_SOURCE'                 : 'LEAD_SOURCE',
            'CAMPAIGN_ID'                 : 'CAMPAIGN_ID',
            'FORECAST_CATEGORY_NAME'      : 'FORECAST_CATEGORY_NAME',
            'SYSTEM_SUB_TYPE_C'           : 'SYSTEM_SUB_TYPE_C',
            'TOTAL_CONTRACT_VALUE_CURRENCY_C' : 'TOTAL_CONTRACT_VALUE_CURRENCY_C',
            'IS_CLOSED'                   : 'IS_CLOSED',
            'IS_WON'                      : 'IS_WON',
            'NEXT_STEP'                   : 'NEXT_STEP',
            'CREATED_DATE'                : 'CREATED_DATE',
            'DESCRIPTION'                 : 'DESCRIPTION',
            'LOSS_REASON_C'               : 'LOSS_REASON_C',
            'LAST_MODIFIED_DATE'          : 'LAST_MODIFIED_DATE'

    }
  }

} %}

{# -------------------------------
   Validate source
-------------------------------- #}
{# -------------------------------
   Resolve company mapping safely
-------------------------------- #}
{% if source == 'salesforce' %}
  {% set company_mapping = mappings.get(source, {}).get(company, {}) %}
{% else %}
  {# Non-salesforce source → bypass safely #}
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
