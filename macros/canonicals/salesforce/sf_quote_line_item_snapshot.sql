{% macro sf_canonical_quote_line_item(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'QUOTE_LINE_ITEM_ID',
        'QUOTE_ID',
        'PRODUCT_ID',
        'QUANTITY',
        'UNIT_PRICE',
        'SERVICE_DATE',
        'DISCOUNT',
        'TOTAL_PRICE',
        'CREATED_DATE',
        'LAST_MODIFIED_DATE'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'QUOTE_LINE_ITEM_ID': 'VARCHAR(18)'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'salesforce': {
    'zeus': {
            'QUOTE_LINE_ITEM_ID'   : 'ID',
            'QUOTE_ID'             : 'QUOTE_ID',
            'PRODUCT_ID'           : 'PRODUCT_2_ID',
            'QUANTITY'             : 'QUANTITY',
            'UNIT_PRICE'           : 'UNIT_PRICE',
            'SERVICE_DATE'         : 'SERVICE_DATE',
            'DISCOUNT'             : 'DISCOUNT',
            'TOTAL_PRICE'          : 'TOTAL_PRICE',
            'CREATED_DATE'         : 'CREATED_DATE',
            'LAST_MODIFIED_DATE'   : 'LAST_MODIFIED_DATE'

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
