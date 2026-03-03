{% macro sf_canonical_account(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
'ACCOUNT_ID',
'ACCOUNT_SOURCE',
'EXTERNAL_ACCOUNT_ID',
'NAME',
'TYPE',
'RECORD_TYPE_NAME_C',
'PARENT_ID',
'PARENT_COMPANY',
'INDUSTRY',
'NUMBER_OF_EMPLOYEES',
'ANNUAL_REVENUE',
'WEBSITE',
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
'OWNER_ID',
'PHONE',
'SITE_ADDRESS_SAME_AS_BILLING_C',
'CREATED_DATE',
'CREATED_BY_ID',
'LAST_MODIFIED_DATE',
'LAST_MODIFIED_BY_ID',
'DESCRIPTION'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'ACCOUNT_ID': 'VARCHAR(18)'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'salesforce': {
    'zeus': {
            'ACCOUNT_ID'                    : 'ID',
            'ACCOUNT_SOURCE'                : 'account_source',
            'EXTERNAL_ACCOUNT_ID'           : 'external_account_id_c',
            'NAME'                          : 'name',
            'TYPE'                          : 'type',
            'RECORD_TYPE_NAME_C'            : 'record_type_name_c',
            'PARENT_ID'                     : 'parent_id',
            'INDUSTRY'                      : 'industry',
            'NUMBER_OF_EMPLOYEES'           : 'number_of_employees',
            'ANNUAL_REVENUE'                : 'revenue_c',
            'WEBSITE'                       : 'website',
            'BILLING_STREET'                : 'billing_street',
            'BILLING_CITY'                  : 'billing_city',
            'BILLING_STATE'                 : 'billing_state',
            'BILLING_POSTAL_CODE'           : 'billing_postal_code',
            'BILLING_COUNTRY'               : 'billing_country',
            'SHIPPING_STREET'               : 'shipping_street',
            'SHIPPING_CITY'                 : 'shipping_city',
            'SHIPPING_STATE'                : 'shipping_state',
            'SHIPPING_POSTAL_CODE'          : 'shipping_postal_code',
            'SHIPPING_COUNTRY'              : 'shipping_country',
            'OWNER_ID'                      : 'owner_id',
            'PHONE'                         : 'phone',
            'SITE_ADDRESS_SAME_AS_BILLING_C': 'site_address_same_as_billing_c',
            'CREATED_DATE'                  : 'created_date',
            'CREATED_BY_ID'                 : 'created_by_id',
            'LAST_MODIFIED_DATE'            : 'last_modified_date',
            'LAST_MODIFIED_BY_ID'           : 'last_modified_by_id',
            'DESCRIPTION'                   : 'description'

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
