{% macro hs_canonical_owner_team(company, sourcesystem) %}

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
        'TEAM_ID',
        'IS_TEAM_PRIMARY'
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
        'TEAM_ID' : 'TEAM_ID',
        'IS_TEAM_PRIMARY' : 'IS_TEAM_PRIMARY'
    },
    'amh': {
        'OWNER_ID' : 'OWNER_ID',
        'TEAM_ID' : 'TEAM_ID',
        'IS_TEAM_PRIMARY' : 'IS_TEAM_PRIMARY'

    },
    'playfly': {
        'OWNER_ID' : 'OWNER_ID',
        'TEAM_ID' : 'TEAM_ID',
        'IS_TEAM_PRIMARY' : 'IS_TEAM_PRIMARY'

    }
  },

  'hubspot_pawville': {
    'wagway': {
        'OWNER_ID' : 'OWNER_ID',
        'TEAM_ID' : 'TEAM_ID',
        'IS_TEAM_PRIMARY' : 'IS_TEAM_PRIMARY'

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
