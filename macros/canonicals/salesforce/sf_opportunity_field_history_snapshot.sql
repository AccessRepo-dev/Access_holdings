{% macro sf_canonical_opportunity_field_history(company, sourcesystem) %}

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
        'OPPORTUNITY_ID',
        'IS_DELETED',
        'CREATED_BY_ID',
        'CREATED_DATE',
        'FIELD',
        'DATA_TYPE',
        'OLD_VALUE',
        'NEW_VALUE'
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
        'ID'               : 'ID',
        'OPPORTUNITY_ID'   : 'OPPORTUNITY_ID',
        'IS_DELETED'       : 'IS_DELETED',
        'CREATED_BY_ID'    : 'CREATED_BY_ID',
        'CREATED_DATE'     : 'CREATED_DATE',
        'FIELD'            : 'FIELD',
        'DATA_TYPE'        : 'DATA_TYPE',
        'OLD_VALUE'        : 'OLD_VALUE',
        'NEW_VALUE'        : 'NEW_VALUE'
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
