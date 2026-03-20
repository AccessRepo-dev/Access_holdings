{% macro hs_canonical_quote(company, sourcesystem) %}

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
        'PROPERTY_HS_TITLE',
        'PROPERTY_HS_QUOTE_AMOUNT',
        'PROPERTY_HS_STATUS',
        'PROPERTY_HS_PAYMENT_STATUS',
        'PROPERTY_HS_LASTMODIFIEDDATE'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
        'ID': 'NUMBER'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'hubspot': {
    'wagway': {
        'ID' : 'ID',
        'PROPERTY_HS_TITLE' : 'PROPERTY_HS_TITLE',
        'PROPERTY_HS_QUOTE_AMOUNT' : 'PROPERTY_HS_QUOTE_AMOUNT',
        'PROPERTY_HS_STATUS' : 'PROPERTY_HS_STATUS',
        'PROPERTY_HS_PAYMENT_STATUS' : 'PROPERTY_HS_PAYMENT_STATUS',
        'PROPERTY_HS_LASTMODIFIEDDATE' : 'PROPERTY_HS_LASTMODIFIEDDATE'
    },
    'amh': {
        'ID' : 'ID',
        'PROPERTY_HS_TITLE' : 'PROPERTY_HS_TITLE',
        'PROPERTY_HS_QUOTE_AMOUNT' : 'PROPERTY_HS_QUOTE_AMOUNT',
        'PROPERTY_HS_STATUS' : 'PROPERTY_HS_STATUS',
        'PROPERTY_HS_PAYMENT_STATUS' : 'PROPERTY_HS_PAYMENT_STATUS',
        'PROPERTY_HS_LASTMODIFIEDDATE' : 'PROPERTY_HS_LASTMODIFIEDDATE'

    },
    'playfly': {
        'ID' : 'ID',
        'PROPERTY_HS_TITLE' : 'PROPERTY_HS_TITLE',
        'PROPERTY_HS_QUOTE_AMOUNT' : 'PROPERTY_HS_QUOTE_AMOUNT',
        'PROPERTY_HS_STATUS' : 'PROPERTY_HS_STATUS',
        'PROPERTY_HS_PAYMENT_STATUS' : 'PROPERTY_HS_PAYMENT_STATUS',
        'PROPERTY_HS_LASTMODIFIEDDATE' : 'PROPERTY_HS_LASTMODIFIEDDATE'

    }
  },

  'hubspot_pawville': {
    'wagway': {
        'ID' : 'ID',
        'PROPERTY_HS_TITLE' : 'PROPERTY_HS_TITLE',
        'PROPERTY_HS_QUOTE_AMOUNT' : 'PROPERTY_HS_QUOTE_AMOUNT',
        'PROPERTY_HS_STATUS' : 'PROPERTY_HS_STATUS',
        'PROPERTY_HS_PAYMENT_STATUS' : 'PROPERTY_HS_PAYMENT_STATUS',
        'PROPERTY_HS_LASTMODIFIEDDATE' : 'PROPERTY_HS_LASTMODIFIEDDATE'

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
