USE DATABASE RAW_DEV;
USE SCHEMA TEST;

CREATE or REPLACE table RAW_DEV.TEST.employeesTable (
  id NUMBER,
  name VARCHAR,
  last_name VARCHAR,
  email VARCHAR,
  zip_code NUMBER
 );


 INSERT INTO RAW_DEV.TEST.employeesTable (id, name, last_name, email, zip_code)
VALUES
  (8, 'John', 'Doe', 'johndoe@example.com', 12345),
  (23, '', 'Smith', 'smithj@example.com', 23456),
  (1, NULL, 'Taylor', 'taylorj@example.com', 34567),
  (99, 'Jane', 'Adams', 'jadams@example.com', 45678),
  (50, 'Alice', 'Brown', '', 56789),
  (51, NULL, 'Lee', 'lee@example.com', 67890),
  (234, 'Michael', '', 'michael@example.com', 78901),
  (56, 'Sara', 'Jones', 'sjones@example.com', 89012),
  (11, '', NULL, 'blanklast@example.com', 90123),
  (12, 'Tom', 'Harris', NULL, 10234);

  select * from RAW_DEV.TEST.employeesTable ;


/* GET THE COUNT OF BLANKS ON COLUMN NAME */

  SELECT snowflake.core.blank_count (SELECT name FROM RAW_DEV.TEST.employeesTable) ;


  SELECT *
  FROM TABLE(SYSTEM$DATA_METRIC_SCAN(
    REF_ENTITY_NAME  => 'RAW_DEV.TEST.employeesTable',
    METRIC_NAME  => 'snowflake.core.blank_count',
    ARGUMENT_NAME => 'name'
   ));


/* UPDATE RECORDS WTH NULL VALUE */ 

UPDATE dq_tutorial_db.sch.employeesTable
  SET name = null
  WHERE dq_tutorial_db.sch.employeesTable.ID IN (
    select ID from table(system$data_metric_scan(
  REF_ENTITY_NAME => 'dq_tutorial_db.sch.employeesTable',
  METRIC_NAME => 'snowflake.core.blank_count',
  ARGUMENT_NAME => 'name'
  )));


  /*CHECK */ 

  SELECT snowflake.core.blank_count (SELECT name FROM dq_tutorial_db.sch.employeesTable)
;


/* MONITOR YOUR CONSUMPTION **/ 



SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.DATA_QUALITY_MONITORING_USAGE_HISTORY
WHERE TRUE
AND START_TIME >= CURRENT_TIMESTAMP - INTERVAL '3 days'
LIMIT 100;


SELECT SUM(CREDITS_USED) FROM SNOWFLAKE.ACCOUNT_USAGE.DATA_QUALITY_MONITORING_USAGE_HISTORY ;  -- 2 CREDITS USED FOR 1 METRIC IN A 5 MIN INTERVAL IN 24 HRS