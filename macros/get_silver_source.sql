{% macro get_silver_source(company, table_name) %}
    {% set company_lower = company | lower %}
    {% set schema_name   = company_lower ~'_silver' %}

    {{ source(schema_name, table_name) }}
{% endmacro %}
