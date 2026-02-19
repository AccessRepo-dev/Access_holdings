{% macro replicate_table_from_dev(source_database, source_schema, table_name) %}
    {%- set current_database = source_database -%}
    {%- set is_ci = var("is_ci_run", false) -%}
    
    {# Determine current schema based on CI/CD #}
    {%- if is_ci -%}
        {%- set current_schema = target.schema -%}
        {{ log("CI Job: Using target schema: " ~ current_schema, info=True) }}
    {%- else -%}
        {%- set current_schema = this.schema -%}
        {{ log("CD Job: Using configured schema: " ~ current_schema, info=True) }}
    {%- endif -%}

    {# Check if table exists in current environment #}
    {% set table_exists_query %}
        SELECT COUNT(*) AS table_count
        FROM {{ current_database }}.INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = UPPER('{{ current_schema }}')
          AND TABLE_NAME = UPPER('{{ table_name }}')
    {% endset %}

    {% set results = run_query(table_exists_query) %}

    {% if execute %}
        {% set table_count = results.columns[0].values()[0] %}

        {% if table_count == 0 %}
            {{
                log(
                    "Table '"
                    ~ table_name
                    ~ "' does not exist in "
                    ~ current_schema
                    ~ " schema. Replicating from source...",
                    info=True,
                )
            }}

            {# Create the table by cloning from source #}
            {% set clone_query %}
                CREATE TABLE IF NOT EXISTS {{ current_database }}.{{ current_schema }}.{{ table_name }}
                CLONE {{ source_database }}.{{ source_schema }}.{{ table_name }}
            {% endset %}

            {% do run_query(clone_query) %}

            {{
                log(
                    "Successfully replicated '" ~ table_name ~ "' from source environment!",
                    info=True,
                )
            }}
        {% else %}
            {{
                log(
                    "Table '"
                    ~ table_name
                    ~ "' already exists. Skipping replication.",
                    info=True,
                )
            }}
        {% endif %}
    {% endif %}
{% endmacro %}