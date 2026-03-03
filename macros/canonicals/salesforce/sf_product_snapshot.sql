{% macro sf_canonical_product(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'PRODUCT_ID',
        'NAME',
        'PRODUCT_CODE',
        'DESCRIPTION',
        'FAMILY',
        'PRODUCT_IS_ACTIVE',
        'CREATED_DATE',
        'LAST_MODIFIED_DATE',
        'QUANTITY_UNIT_OF_MEASURE'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'PRODUCT_ID': 'VARCHAR(18)'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'salesforce': {
    'zeus': {
            'PRODUCT_ID'                 : 'ID',
            'NAME'                       : 'NAME',
            'PRODUCT_CODE'               : 'PRODUCT_CODE',
            'DESCRIPTION'                : 'DESCRIPTION',
            'FAMILY'                     : 'FAMILY',
            'PRODUCT_IS_ACTIVE'          : 'IS_ACTIVE',
            'CREATED_DATE'               : 'CREATED_DATE',
            'LAST_MODIFIED_DATE'         : 'LAST_MODIFIED_DATE',
            'QUANTITY_UNIT_OF_MEASURE'   : 'QUANTITY_UNIT_OF_MEASURE'

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
