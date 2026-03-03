{% macro sf_canonical_opportunity_line_item(company, sourcesystem) %}

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
        'SORT_ORDER',
        'PRICEBOOK_ENTRY_ID',
        'PRODUCT_2_ID',
        'PRODUCT_CODE',
        'NAME',
        'QUANTITY',
        'DISCOUNT',
        'TOTAL_PRICE',
        'UNIT_PRICE',
        'LIST_PRICE',
        'SERVICE_DATE',
        'DESCRIPTION',
        'CREATED_DATE',
        'CREATED_BY_ID',
        'LAST_MODIFIED_DATE',
        'LAST_MODIFIED_BY_ID',
        'SYSTEM_MODSTAMP',
        'IS_DELETED',
        'LAST_VIEWED_DATE',
        'LAST_REFERENCED_DATE'
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
            'ID'                    : 'ID',
            'OPPORTUNITY_ID'        : 'OPPORTUNITY_ID',
            'SORT_ORDER'            : 'SORT_ORDER',
            'PRICEBOOK_ENTRY_ID'    : 'PRICEBOOK_ENTRY_ID',
            'PRODUCT_2_ID'          : 'PRODUCT_2_ID',
            'PRODUCT_CODE'          : 'PRODUCT_CODE',
            'NAME'                  : 'NAME',
            'QUANTITY'              : 'QUANTITY',
            'DISCOUNT'              : 'DISCOUNT',
            'TOTAL_PRICE'           : 'TOTAL_PRICE',
            'UNIT_PRICE'            : 'UNIT_PRICE',
            'LIST_PRICE'            : 'LIST_PRICE',
            'SERVICE_DATE'          : 'SERVICE_DATE',
            'DESCRIPTION'           : 'DESCRIPTION',
            'CREATED_DATE'          : 'CREATED_DATE',
            'CREATED_BY_ID'         : 'CREATED_BY_ID',
            'LAST_MODIFIED_DATE'    : 'LAST_MODIFIED_DATE',
            'LAST_MODIFIED_BY_ID'   : 'LAST_MODIFIED_BY_ID',
            'SYSTEM_MODSTAMP'       : 'SYSTEM_MODSTAMP',
            'IS_DELETED'            : 'IS_DELETED',
            'LAST_VIEWED_DATE'      : 'LAST_VIEWED_DATE',
            'LAST_REFERENCED_DATE'  : 'LAST_REFERENCED_DATE'


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
