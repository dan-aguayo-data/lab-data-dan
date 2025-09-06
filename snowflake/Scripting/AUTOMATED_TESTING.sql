
DECLARE
create_table STRING;
v_table STRING;
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
rs_compiled_result RESULTSET;
BEGIN
    LET res RESULTSET := (SELECT TABLE_NAME  FROM  INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'pattern' );
    create_table := 'CREATE OR REPLACE TEMPORARY TABLE TMP_DUMP (prod_table_name STRING,row_count_prod NUMBER,row_count_dev NUMBER, difference NUMBER, diff_flag STRING)';
    EXECUTE IMMEDIATE create_table;
    FOR rec IN res  DO
        v_table:= rec.TABLE_NAME;
        v_table_prod_sql := 'SELECT COUNT (*) AS COUNT FROM '||v_table;  --'SELECT COUNT (*) AS COUNT FROM COMMON_PROD.ERP.'|| v_table
        v_table_dev_sql := 'SELECT COUNT (*) AS COUNT FROM '||v_table||'_TMP'; 
        rs_prod := (EXECUTE IMMEDIATE v_table_prod_sql);
        LET c1 CURSOR FOR rs_prod;
        OPEN c1;
        FETCH c1 INTO rs_count_prod;
        rs_dev := (EXECUTE IMMEDIATE v_table_dev_sql);
        LET c2 CURSOR FOR rs_dev;
        OPEN c2;
        FETCH c2 INTO rs_count_dev;
        diff := rs_count_prod - rs_count_dev;
        IF (diff = 0) THEN
        flag := '';
        ELSE
        flag := 'DIFFERENCE';
        END IF; 
