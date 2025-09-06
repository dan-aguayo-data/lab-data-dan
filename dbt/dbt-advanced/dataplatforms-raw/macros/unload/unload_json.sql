{% macro unload_json() %}

  {% set query %}
    EXECUTE IMMEDIATE $$
    DECLARE
      query_unload STRING;
      datetime_str STRING;
    BEGIN 
      SELECT to_char(sysdate(),'yyyymmddhh24miss') INTO :datetime_str;
      query_unload := 'copy into @LANDING.SNOWPIPE_DEV.CES_SF_UNLOAD_DEV_STAGE/SF_Data_' || datetime_str || ' from 
      (SELECT array_agg(OBJECT_CONSTRUCT(*)) FROM LANDING.ATP_MIGRATION_PROD.SCHEME_TEST) file_format = (type = json);';              
      EXECUTE IMMEDIATE :query_unload;
      --RETURN :query_unload;
    END;
    $$;
  {% endset %}

  {% do run_query(query) %}
{% endmacro %}