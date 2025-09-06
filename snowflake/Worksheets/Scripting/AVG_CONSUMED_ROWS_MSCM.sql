



DECLARE
create_table STRING;
v_table STRING;
v_schema STRING;
v_table_prod_sql STRING;
v_table_dev_sql STRING;
rs_prod RESULTSET;
rs_dev RESULTSET;
rs_query STRING;
rs_compiled STRING;
rs_count_prod int;
rs_count_dev int;
diff int;
flag STRING;
day_range NUMBER;
avg_daily FLOAT;
rs_compiled_result RESULTSET;
BEGIN
    LET res RESULTSET := (SELECT DISTINCT A.TABLE_NAME, A.TABLE_SCHEMA FROM CES_ERP.INFORMATION_SCHEMA.COLUMNS AS A INNER JOIN CES_ERP.INFORMATION_SCHEMA.TABLES AS B ON  A.TABLE_NAME = B.TABLE_NAME AND B.ROW_COUNT > 1000 WHERE A.COLUMN_NAME = '_FIVETRAN_SYNCED');
    create_table := 'CREATE OR REPLACE TABLE RAW_DEV.TEST.FIVETRAN_ERP_COUNT (prod_table_name STRING,row_count_prod NUMBER, day_range NUMBER, avg_daily FLOAT)';
    EXECUTE IMMEDIATE create_table;
    FOR rec IN res  DO
        v_table:= rec.TABLE_NAME;
        v_schema := rec.TABLE_SCHEMA;
        v_table_prod_sql := 'SELECT COUNT(*) AS COUNT FROM CES_ERP.' || v_schema || '.' || v_table ||' WHERE _fivetran_synced > ''2025-06-23'' AND _fivetran_synced <= ''2025-06-30''';
        rs_prod := (EXECUTE IMMEDIATE v_table_prod_sql);
        LET c1 CURSOR FOR rs_prod;
        OPEN c1;
        FETCH c1 INTO rs_count_prod;
        day_range := 7 ;
        avg_daily := rs_count_prod / 7.0;
        rs_query := 'INSERT INTO RAW_DEV.TEST.FIVETRAN_ERP_COUNT VALUES (''' || v_table || ''', ' || rs_count_prod ||','  || day_range ||','||avg_daily||')';
        EXECUTE IMMEDIATE rs_query;
    END FOR;
    rs_compiled := 'SELECT * FROM RAW_DEV.TEST.FIVETRAN_ERP_COUNT';
    rs_compiled_result := (EXECUTE IMMEDIATE rs_compiled);
RETURN
    -- Return resul
    TABLE(rs_compiled_result);
END;