{% macro hs_canonical_owner(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'OWNER_ID',
        'FIRST_NAME',
        'LAST_NAME',
        'EMAIL',
        'UPDATED_AT'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
        'OWNER_ID': 'NUMBER'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'hubspot': {
    'wagway': {
        'OWNER_ID' : 'OWNER_ID',
        'FIRST_NAME' : 'FIRST_NAME',
        'LAST_NAME' : 'LAST_NAME',
        'EMAIL' : 'EMAIL',
        'UPDATED_AT' : 'UPDATED_AT'
    },
    'amh': {
        'OWNER_ID' : 'OWNER_ID',
        'FIRST_NAME' : 'FIRST_NAME',
        'LAST_NAME' : 'LAST_NAME',
        'EMAIL' : 'EMAIL',
        'UPDATED_AT' : 'UPDATED_AT'

    },
    'playfly': {
        'OWNER_ID' : 'OWNER_ID',
        'FIRST_NAME' : 'FIRST_NAME',
        'LAST_NAME' : 'LAST_NAME',
        'EMAIL' : 'EMAIL',
        'UPDATED_AT' : 'UPDATED_AT'

    }
  },

  'hubspot_pawville': {
    'wagway': {
        'OWNER_ID' : 'OWNER_ID',
        'FIRST_NAME' : 'FIRST_NAME',
        'LAST_NAME' : 'LAST_NAME',
        'EMAIL' : 'EMAIL',
        'UPDATED_AT' : 'UPDATED_AT'

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
