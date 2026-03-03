{% macro hs_canonical_deal_contact(company, sourcesystem) %}

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
  'CATEGORY',
  'CONTACT_ID',
  'TYPE_ID'
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
      'DEAL_ID': 'DEAL_ID',
      'CATEGORY': 'CATEGORY',
      'CONTACT_ID': 'CONTACT_ID',
      'TYPE_ID': 'TYPE_ID'
    },
    'amh': {
      'DEAL_ID': 'DEAL_ID',
      'CATEGORY': 'CATEGORY',
      'CONTACT_ID': 'CONTACT_ID',
      'TYPE_ID': 'TYPE_ID'
    },
    'playfly': {
      'DEAL_ID': 'DEAL_ID',
      'CATEGORY': 'CATEGORY',
      'CONTACT_ID': 'CONTACT_ID',
      'TYPE_ID': 'TYPE_ID'
    }
  },

  'hubspot_pawville': {
    'wagway': {
      'DEAL_ID': 'DEAL_ID',
      'CATEGORY': 'CATEGORY',
      'CONTACT_ID': 'CONTACT_ID',
      'TYPE_ID': 'TYPE_ID'
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
