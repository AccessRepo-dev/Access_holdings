{% macro get_raw_source(company, sourcesystem, table_name) %}
    {% set company_lower = company | lower %}
    {% set system_lower  = sourcesystem | lower %}
    {% set schema_name   = company_lower ~ '_' ~ system_lower ~ '_raw' %}

    {{ source(schema_name, table_name) }}
{% endmacro %}
