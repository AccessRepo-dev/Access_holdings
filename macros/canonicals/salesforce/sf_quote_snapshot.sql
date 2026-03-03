{% macro sf_canonical_quote(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'QUOTE_ID',
        'OPPORTUNITY_ID',
        'ACCOUNT_ID',
        'STATUS',
        'QUOTE_NUMBER',
        'NAME',
        'EXPIRATION_DATE',
        'BILLING_STREET',
        'BILLING_CITY',
        'BILLING_STATE',
        'BILLING_POSTAL_CODE',
        'BILLING_COUNTRY',
        'SHIPPING_STREET',
        'SHIPPING_CITY',
        'SHIPPING_STATE',
        'SHIPPING_POSTAL_CODE',
        'SHIPPING_COUNTRY',
        'DISCOUNT',
        'GRAND_TOTAL',
        'CREATED_DATE',
        'LAST_MODIFIED_DATE',
        'OWNER_ID',
        'PRICEBOOK_2_ID'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'QUOTE_ID': 'VARCHAR(18)'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'salesforce': {
    'zeus': {
            'QUOTE_ID'                : 'ID',
            'OPPORTUNITY_ID'          : 'OPPORTUNITY_ID',
            'ACCOUNT_ID'              : 'ACCOUNT_ID',
            'STATUS'                  : 'STATUS',
            'QUOTE_NUMBER'            : 'QUOTE_NUMBER',
            'NAME'                    : 'NAME',
            'EXPIRATION_DATE'         : 'EXPIRATION_DATE',
            'BILLING_STREET'          : 'BILLING_STREET',
            'BILLING_CITY'            : 'BILLING_CITY',
            'BILLING_STATE'           : 'BILLING_STATE',
            'BILLING_POSTAL_CODE'     : 'BILLING_POSTAL_CODE',
            'BILLING_COUNTRY'         : 'BILLING_COUNTRY',
            'SHIPPING_STREET'         : 'SHIPPING_STREET',
            'SHIPPING_CITY'           : 'SHIPPING_CITY',
            'SHIPPING_STATE'          : 'SHIPPING_STATE',
            'SHIPPING_POSTAL_CODE'    : 'SHIPPING_POSTAL_CODE',
            'SHIPPING_COUNTRY'        : 'SHIPPING_COUNTRY',
            'DISCOUNT'                : 'DISCOUNT',
            'GRAND_TOTAL'             : 'GRAND_TOTAL',
            'CREATED_DATE'            : 'CREATED_DATE',
            'LAST_MODIFIED_DATE'      : 'LAST_MODIFIED_DATE',
            'OWNER_ID'                : 'OWNER_ID',
            'PRICEBOOK_2_ID'          : 'PRICEBOOK_2_ID'

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
