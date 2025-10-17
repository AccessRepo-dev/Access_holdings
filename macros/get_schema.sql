{# 
    These macros help dynamically fetch the correct source schema based on the provided company name and source system for a particular zone. 
    They simplify referencing raw, silver, and gold layer sources without hardcoding schema names.
#}

-- Raw
{% macro get_raw_source(company, sourcesystem, table_name) %}
    {% set company_lower = company | lower %}
    {% set system_lower  = sourcesystem | lower %}
    {% set schema_name   = company_lower ~ '_' ~ system_lower ~ '_raw' %}

    {{ source(schema_name, table_name) }}
{% endmacro %}

-- Silver
{% macro get_silver_source(company, table_name) %}
    {% set company_lower = company | lower %}
    {% set schema_name   = company_lower ~ '_silver' %}

    {{ source(schema_name, table_name) }}
{% endmacro %}

-- Gold
{% macro get_gold_source(company, table_name) %}
    {% set company_lower = company | lower %}
    {% set schema_name   = company_lower ~ '_gold' %}

    {{ source(schema_name, table_name) }}
{% endmacro %}

