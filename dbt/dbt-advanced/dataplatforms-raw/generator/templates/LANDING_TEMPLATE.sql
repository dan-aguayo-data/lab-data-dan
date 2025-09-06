{{'{%- set trimmed_source_rel = model.name | replace("LANDING_ORACLE_","") -%}'}}

{{'{{  
    config(
        alias=trimmed_source_rel
    )
}}'}}

WITH SOURCE AS (
    SELECT
        *
    FROM
        {{'{{'}} source('LANDING_ORACLE', 'AWS_RDS_STAGE_CES_MSCM') {{'}}'}}
    WHERE METADATA:"table-name"='{{TABLE_NAME}}' AND DATA is not null
)

SELECT
{% for column in TABLE_INFO['columns'] %}    {{"nullif(" if column['nullable'] == "Y" else ""}}N.DATA:{{column['name']}}{{",'')" if column['nullable'] == "Y" else ""}}::{{MAP_COLUMN(column['name'], column['data_type'])}} as {{column['name'] | upper }},
{% endfor %}    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N