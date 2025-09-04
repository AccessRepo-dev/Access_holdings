{% macro audit_failures(results) %}
    {% for res in results if res.status != 'success' %}
        update PIPELINE_AUDIT_DB.AUDIT_SCHEMA.pipeline_audit_logs
        set STATUS = 'FAILED',
            ENDTIME = current_timestamp(),
            RUN_TIME = datediff('second', STARTTIME, current_timestamp())
            FAILURE_REASON = '{{ res.message | replace("'", "''") }}'
        where ID = (
            select max(ID)
            from PIPELINE_AUDIT_DB.AUDIT_SCHEMA.pipeline_audit_logs
            where TABLE_NAME = '{{ res.node.name }}'
              and STATUS = 'STARTED'
        );
    {% endfor %}
{% endmacro %}
