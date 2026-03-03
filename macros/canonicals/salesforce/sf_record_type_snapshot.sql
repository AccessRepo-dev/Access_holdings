{% macro sf_canonical_record_type(company, sourcesystem) %}

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
        'NAME',
        'DEVELOPER_NAME',
        'NAMESPACE_PREFIX',
        'DESCRIPTION',
        'BUSINESS_PROCESS_ID',
        'SOBJECT_TYPE',
        'RECORD_TYPE_IS_ACTIVE',
        'CREATED_BY_ID',
        'CREATED_DATE',
        'LAST_MODIFIED_BY_ID',
        'LAST_MODIFIED_DATE',
        'SYSTEM_MODSTAMP',
        'IS_PERSON_TYPE'
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
            'RECORD_TYPE_ID'        : 'ID',
            'NAME'                  : 'NAME',
            'DEVELOPER_NAME'        : 'DEVELOPER_NAME',
            'NAMESPACE_PREFIX'      : 'NAMESPACE_PREFIX',
            'DESCRIPTION'           : 'DESCRIPTION',
            'BUSINESS_PROCESS_ID'   : 'BUSINESS_PROCESS_ID',
            'SOBJECT_TYPE'          : 'SOBJECT_TYPE',
            'RECORD_TYPE_IS_ACTIVE' : 'IS_ACTIVE',
            'CREATED_BY_ID'         : 'CREATED_BY_ID',
            'CREATED_DATE'          : 'CREATED_DATE',
            'LAST_MODIFIED_BY_ID'   : 'LAST_MODIFIED_BY_ID',
            'LAST_MODIFIED_DATE'    : 'LAST_MODIFIED_DATE',
            'SYSTEM_MODSTAMP'       : 'SYSTEM_MODSTAMP'
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
