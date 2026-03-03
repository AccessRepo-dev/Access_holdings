{% macro hs_canonical_line_item(company, sourcesystem) %}

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
        'PRODUCT_ID',
        'PROPERTY_INVOICE_ITEM_ID',
        'PROPERTY_DESCRIPTION',
        'PROPERTY_NAME',
        'PROPERTY_AMOUNT',
        'PROPERTY_QUANTITY',
        'PROPERTY_HS_LINE_ITEM_CURRENCY_CODE',
        'PROPERTY_HS_MARGIN_ACV',
        'PROPERTY_HS_MARGIN_ARR',
        'PROPERTY_HS_MARGIN_MRR',
        'PROPERTY_HS_MARGIN_TCV',
        'PROPERTY_HS_PRICING_MODEL',
        'PROPERTY_HS_LASTMODIFIEDDATE'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
        'ID': 'NUMBER'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'hubspot': {
    'wagway': {
            'ID'                                   : 'ID',
            'PRODUCT_ID'                           : 'PRODUCT_ID',
            'PROPERTY_INVOICE_ITEM_ID'             : 'PROPERTY_INVOICE_ITEM_ID',
            'PROPERTY_DESCRIPTION'                 : 'PROPERTY_DESCRIPTION',
            'PROPERTY_NAME'                        : 'PROPERTY_NAME',
            'PROPERTY_AMOUNT'                      : 'PROPERTY_AMOUNT',
            'PROPERTY_QUANTITY'                    : 'PROPERTY_QUANTITY',
            'PROPERTY_HS_LINE_ITEM_CURRENCY_CODE'  : 'PROPERTY_HS_LINE_ITEM_CURRENCY_CODE',
            'PROPERTY_HS_MARGIN_ACV'               : 'PROPERTY_HS_MARGIN_ACV',
            'PROPERTY_HS_MARGIN_ARR'               : 'PROPERTY_HS_MARGIN_ARR',
            'PROPERTY_HS_MARGIN_MRR'               : 'PROPERTY_HS_MARGIN_MRR',
            'PROPERTY_HS_MARGIN_TCV'               : 'PROPERTY_HS_MARGIN_TCV',
            'PROPERTY_HS_PRICING_MODEL'            : 'PROPERTY_HS_PRICING_MODEL',
            'PROPERTY_HS_LASTMODIFIEDDATE'         : 'PROPERTY_HS_LASTMODIFIEDDATE'
    },
    'amh': {
            'ID'                                   : 'ID',
            'PRODUCT_ID'                           : 'PRODUCT_ID',
            'PROPERTY_DESCRIPTION'                 : 'PROPERTY_DESCRIPTION',
            'PROPERTY_NAME'                        : 'PROPERTY_NAME',
            'PROPERTY_AMOUNT'                      : 'PROPERTY_AMOUNT',
            'PROPERTY_QUANTITY'                    : 'PROPERTY_QUANTITY',
            'PROPERTY_HS_LINE_ITEM_CURRENCY_CODE'  : 'PROPERTY_HS_LINE_ITEM_CURRENCY_CODE',
            'PROPERTY_HS_MARGIN_ACV'               : 'PROPERTY_HS_MARGIN_ACV',
            'PROPERTY_HS_MARGIN_ARR'               : 'PROPERTY_HS_MARGIN_ARR',
            'PROPERTY_HS_MARGIN_MRR'               : 'PROPERTY_HS_MARGIN_MRR',
            'PROPERTY_HS_MARGIN_TCV'               : 'PROPERTY_HS_MARGIN_TCV',
            'PROPERTY_HS_PRICING_MODEL'            : 'PROPERTY_HS_PRICING_MODEL',
            'PROPERTY_HS_LASTMODIFIEDDATE'         : 'PROPERTY_HS_LASTMODIFIEDDATE'

    },
    'playfly': {
            'ID'                                   : 'ID',
            'PRODUCT_ID'                           : 'PRODUCT_ID',
            'PROPERTY_DESCRIPTION'                 : 'PROPERTY_DESCRIPTION',
            'PROPERTY_NAME'                        : 'PROPERTY_NAME',
            'PROPERTY_AMOUNT'                      : 'PROPERTY_AMOUNT',
            'PROPERTY_QUANTITY'                    : 'PROPERTY_QUANTITY',
            'PROPERTY_HS_LINE_ITEM_CURRENCY_CODE'  : 'PROPERTY_HS_LINE_ITEM_CURRENCY_CODE',
            'PROPERTY_HS_MARGIN_ACV'               : 'PROPERTY_HS_MARGIN_ACV',
            'PROPERTY_HS_MARGIN_ARR'               : 'PROPERTY_HS_MARGIN_ARR',
            'PROPERTY_HS_MARGIN_MRR'               : 'PROPERTY_HS_MARGIN_MRR',
            'PROPERTY_HS_MARGIN_TCV'               : 'PROPERTY_HS_MARGIN_TCV',
            'PROPERTY_HS_PRICING_MODEL'            : 'PROPERTY_HS_PRICING_MODEL',
            'PROPERTY_HS_LASTMODIFIEDDATE'         : 'PROPERTY_HS_LASTMODIFIEDDATE'

    }
  },

  'hubspot_pawville': {
    'wagway': {
            'ID'                                   : 'ID',
            'PRODUCT_ID'                           : 'PRODUCT_ID',
            'PROPERTY_INVOICE_ITEM_ID'             : 'PROPERTY_INVOICE_ITEM_ID',
            'PROPERTY_DESCRIPTION'                 : 'PROPERTY_DESCRIPTION',
            'PROPERTY_NAME'                        : 'PROPERTY_NAME',
            'PROPERTY_AMOUNT'                      : 'PROPERTY_AMOUNT',
            'PROPERTY_QUANTITY'                    : 'PROPERTY_QUANTITY',
            'PROPERTY_HS_LINE_ITEM_CURRENCY_CODE'  : 'PROPERTY_HS_LINE_ITEM_CURRENCY_CODE',
            'PROPERTY_HS_MARGIN_ACV'               : 'PROPERTY_HS_MARGIN_ACV',
            'PROPERTY_HS_MARGIN_ARR'               : 'PROPERTY_HS_MARGIN_ARR',
            'PROPERTY_HS_MARGIN_MRR'               : 'PROPERTY_HS_MARGIN_MRR',
            'PROPERTY_HS_MARGIN_TCV'               : 'PROPERTY_HS_MARGIN_TCV',
            'PROPERTY_HS_PRICING_MODEL'            : 'PROPERTY_HS_PRICING_MODEL',
            'PROPERTY_HS_LASTMODIFIEDDATE'         : 'PROPERTY_HS_LASTMODIFIEDDATE'

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
