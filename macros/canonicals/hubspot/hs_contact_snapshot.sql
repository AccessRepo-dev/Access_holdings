{% macro hs_canonical_contact(company, sourcesystem) %}

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
  'PROPERTY_FIRSTNAME',
  'PROPERTY_LASTNAME',
  'PROPERTY_EMAIL',
  'PROPERTY_PHONE',
  'PROPERTY_MOBILEPHONE',
  'PROPERTY_HS_CALCULATED_PHONE_NUMBER',
  'PROPERTY_HS_CALCULATED_MOBILE_NUMBER',
  'PROPERTY_CLUB_C',
  'PROPERTY_GINGR_EMAIL',
  'PROPERTY_LIFECYCLESTAGE',
  'PROPERTY_HUBSPOT_OWNER_ID',
  'PROPERTY_JOBTITLE',
  'PROPERTY_CREATEDATE',
  'PROPERTY_FIRST_DEAL_CREATED_DATE',
  'PROPERTY_HS_LEAD_STATUS',
  'PROPERTY_LEADSTATUS',
  'PROPERTY_HS_IS_UNWORKED',
  'PROPERTY_ASSOCIATEDCOMPANYID',
  'PROPERTY_ADDRESS',
  'PROPERTY_CITY',
  'PROPERTY_STATE',
  'PROPERTY_COUNTRY',
  'PROPERTY_FAX',
  'PROPERTY_HS_TIMEZONE',
  'PROPERTY_MIDDLE_NAME',
  'PROPERTY_LASTMODIFIEDDATE'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'ID': 'NUMBER'
} %}

{# -------------------------------
   Source + contact mappings
-------------------------------- #}
{% set mappings = {

  'hubspot': {
    'wagway': {
            'ID'                                   : 'ID',
            'PROPERTY_FIRSTNAME'                   : 'PROPERTY_FIRSTNAME',
            'PROPERTY_LASTNAME'                    : 'PROPERTY_LASTNAME',
            'PROPERTY_EMAIL'                       : 'PROPERTY_EMAIL',
            'PROPERTY_PHONE'                       : 'PROPERTY_PHONE',
            'PROPERTY_MOBILEPHONE'                 : 'PROPERTY_MOBILEPHONE',
            'PROPERTY_HS_CALCULATED_PHONE_NUMBER'  : 'PROPERTY_HS_CALCULATED_PHONE_NUMBER',
            'PROPERTY_HS_CALCULATED_MOBILE_NUMBER' : 'PROPERTY_HS_CALCULATED_MOBILE_NUMBER',
            'PROPERTY_CLUB_C'                      : 'PROPERTY_CLUB_C',
            'PROPERTY_GINGR_EMAIL'                 : 'PROPERTY_GINGR_EMAIL',
            'PROPERTY_LIFECYCLESTAGE'              : 'PROPERTY_LIFECYCLESTAGE',
            'PROPERTY_HUBSPOT_OWNER_ID'             : 'PROPERTY_HUBSPOT_OWNER_ID',
            'PROPERTY_JOBTITLE'                    : 'PROPERTY_JOBTITLE',
            'PROPERTY_CREATEDATE'                  : 'PROPERTY_CREATEDATE',
            'PROPERTY_FIRST_DEAL_CREATED_DATE'     : 'PROPERTY_FIRST_DEAL_CREATED_DATE',
            'PROPERTY_HS_LEAD_STATUS'              : 'PROPERTY_HS_LEAD_STATUS',
            'PROPERTY_LEADSTATUS'                  : 'PROPERTY_LEADSTATUS',
            'PROPERTY_HS_IS_UNWORKED'               : 'PROPERTY_HS_IS_UNWORKED',
            'PROPERTY_ASSOCIATEDCOMPANYID'         : 'PROPERTY_ASSOCIATEDCOMPANYID',
            'PROPERTY_ADDRESS'                     : 'PROPERTY_ADDRESS',
            'PROPERTY_CITY'                        : 'PROPERTY_CITY',
            'PROPERTY_STATE'                       : 'PROPERTY_STATE',
            'PROPERTY_COUNTRY'                     : 'PROPERTY_COUNTRY',
            'PROPERTY_FAX'                         : 'PROPERTY_FAX',
            'PROPERTY_HS_TIMEZONE'                 : 'PROPERTY_HS_TIMEZONE',
            'PROPERTY_LASTMODIFIEDDATE'            : 'PROPERTY_LASTMODIFIEDDATE'
    },
    'playfly': {
            'ID'                                   : 'ID',
            'PROPERTY_FIRSTNAME'                   : 'PROPERTY_FIRSTNAME',
            'PROPERTY_LASTNAME'                    : 'PROPERTY_LASTNAME',
            'PROPERTY_EMAIL'                       : 'PROPERTY_EMAIL',
            'PROPERTY_PHONE'                       : 'PROPERTY_PHONE',
            'PROPERTY_MOBILEPHONE'                 : 'PROPERTY_MOBILEPHONE',
            'PROPERTY_HS_CALCULATED_PHONE_NUMBER'  : 'PROPERTY_HS_CALCULATED_PHONE_NUMBER',
            'PROPERTY_HS_CALCULATED_MOBILE_NUMBER' : 'PROPERTY_HS_CALCULATED_MOBILE_NUMBER',
            'PROPERTY_LIFECYCLESTAGE'              : 'PROPERTY_LIFECYCLESTAGE',
            'PROPERTY_HUBSPOT_OWNER_ID'             : 'PROPERTY_HUBSPOT_OWNER_ID',
            'PROPERTY_JOBTITLE'                    : 'PROPERTY_JOBTITLE',
            'PROPERTY_CREATEDATE'                  : 'PROPERTY_CREATEDATE',
            'PROPERTY_FIRST_DEAL_CREATED_DATE'     : 'PROPERTY_FIRST_DEAL_CREATED_DATE',
            'PROPERTY_HS_LEAD_STATUS'              : 'PROPERTY_HS_LEAD_STATUS',
            'PROPERTY_HS_IS_UNWORKED'               : 'PROPERTY_HS_IS_UNWORKED',
            'PROPERTY_ASSOCIATEDCOMPANYID'         : 'PROPERTY_ASSOCIATEDCOMPANYID',
            'PROPERTY_ADDRESS'                     : 'PROPERTY_ADDRESS',
            'PROPERTY_CITY'                        : 'PROPERTY_CITY',
            'PROPERTY_STATE'                       : 'PROPERTY_STATE',
            'PROPERTY_COUNTRY'                     : 'PROPERTY_COUNTRY',
            'PROPERTY_FAX'                         : 'PROPERTY_FAX',
            'PROPERTY_HS_TIMEZONE'                 : 'PROPERTY_HS_TIMEZONE',
            'PROPERTY_LASTMODIFIEDDATE'            : 'PROPERTY_LASTMODIFIEDDATE'
    },
    'amh': {
            'ID'                                   : 'ID',
            'PROPERTY_FIRSTNAME'                   : 'PROPERTY_FIRSTNAME',
            'PROPERTY_LASTNAME'                    : 'PROPERTY_LASTNAME',
            'PROPERTY_EMAIL'                       : 'PROPERTY_EMAIL',
            'PROPERTY_PHONE'                       : 'PROPERTY_PHONE',
            'PROPERTY_MOBILEPHONE'                 : 'PROPERTY_MOBILEPHONE',
            'PROPERTY_HS_CALCULATED_PHONE_NUMBER'  : 'PROPERTY_HS_CALCULATED_PHONE_NUMBER',
            'PROPERTY_HS_CALCULATED_MOBILE_NUMBER' : 'PROPERTY_HS_CALCULATED_MOBILE_NUMBER',
            'PROPERTY_LIFECYCLESTAGE'              : 'PROPERTY_LIFECYCLESTAGE',
            'PROPERTY_HUBSPOT_OWNER_ID'             : 'PROPERTY_HUBSPOT_OWNER_ID',
            'PROPERTY_JOBTITLE'                    : 'PROPERTY_JOBTITLE',
            'PROPERTY_CREATEDATE'                  : 'PROPERTY_CREATEDATE',
            'PROPERTY_FIRST_DEAL_CREATED_DATE'     : 'PROPERTY_FIRST_DEAL_CREATED_DATE',
            'PROPERTY_HS_LEAD_STATUS'              : 'PROPERTY_HS_LEAD_STATUS',
            'PROPERTY_HS_IS_UNWORKED'               : 'PROPERTY_HS_IS_UNWORKED',
            'PROPERTY_ASSOCIATEDCOMPANYID'         : 'PROPERTY_ASSOCIATEDCOMPANYID',
            'PROPERTY_ADDRESS'                     : 'PROPERTY_ADDRESS',
            'PROPERTY_CITY'                        : 'PROPERTY_CITY',
            'PROPERTY_STATE'                       : 'PROPERTY_STATE',
            'PROPERTY_COUNTRY'                     : 'PROPERTY_COUNTRY',
            'PROPERTY_FAX'                         : 'PROPERTY_FAX',
            'PROPERTY_HS_TIMEZONE'                 : 'PROPERTY_HS_TIMEZONE',
            'PROPERTY_MIDDLE_NAME'                 : 'PROPERTY_MIDDLE_NAME',
            'PROPERTY_LASTMODIFIEDDATE'            : 'PROPERTY_LASTMODIFIEDDATE'
  }
  },

  'hubspot_pawville': {
    'wagway': {
            'ID'                                   : 'ID',
            'PROPERTY_FIRSTNAME'                   : 'PROPERTY_FIRSTNAME',
            'PROPERTY_LASTNAME'                    : 'PROPERTY_LASTNAME',
            'PROPERTY_EMAIL'                       : 'PROPERTY_EMAIL',
            'PROPERTY_PHONE'                       : 'PROPERTY_PHONE',
            'PROPERTY_MOBILEPHONE'                 : 'PROPERTY_MOBILEPHONE',
            'PROPERTY_HS_CALCULATED_PHONE_NUMBER'  : 'PROPERTY_HS_CALCULATED_PHONE_NUMBER',
            'PROPERTY_HS_CALCULATED_MOBILE_NUMBER' : 'PROPERTY_HS_CALCULATED_MOBILE_NUMBER',
            'PROPERTY_GINGR_EMAIL'                 : 'PROPERTY_GINGR_EMAIL',
            'PROPERTY_LIFECYCLESTAGE'              : 'PROPERTY_LIFECYCLESTAGE',
            'PROPERTY_HUBSPOT_OWNER_ID'             : 'PROPERTY_HUBSPOT_OWNER_ID',
            'PROPERTY_JOBTITLE'                    : 'PROPERTY_JOBTITLE',
            'PROPERTY_CREATEDATE'                  : 'PROPERTY_CREATEDATE',
            'PROPERTY_FIRST_DEAL_CREATED_DATE'     : 'PROPERTY_FIRST_DEAL_CREATED_DATE',
            'PROPERTY_HS_LEAD_STATUS'              : 'PROPERTY_HS_LEAD_STATUS',
            'PROPERTY_HS_IS_UNWORKED'               : 'PROPERTY_HS_IS_UNWORKED',
            'PROPERTY_ASSOCIATEDCOMPANYID'         : 'PROPERTY_ASSOCIATEDCOMPANYID',
            'PROPERTY_ADDRESS'                     : 'PROPERTY_ADDRESS',
            'PROPERTY_CITY'                        : 'PROPERTY_CITY',
            'PROPERTY_STATE'                       : 'PROPERTY_STATE',
            'PROPERTY_COUNTRY'                     : 'PROPERTY_COUNTRY',
            'PROPERTY_FAX'                         : 'PROPERTY_FAX',
            'PROPERTY_HS_TIMEZONE'                 : 'PROPERTY_HS_TIMEZONE',
            'PROPERTY_LASTMODIFIEDDATE'            : 'PROPERTY_LASTMODIFIEDDATE'
    }
  }

} %}

{# -------------------------------
   Validate source
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
