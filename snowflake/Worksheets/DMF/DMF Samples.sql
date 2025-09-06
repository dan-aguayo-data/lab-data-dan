USE DATABASE RAW_DEV;
USE SCHEMA TEST;

CREATE OR REPLACE TABLE RAW_DEV.TEST.CUSTOMERS (
  account_number NUMBER(38,0),
  first_name VARCHAR(16777216),
  last_name VARCHAR(16777216),
  email VARCHAR(16777216),
  phone VARCHAR(16777216),
  created_at TIMESTAMP_TZ(9),
  street VARCHAR(16777216),
  city VARCHAR(16777216),
  state VARCHAR(16777216),
  country VARCHAR(16777216),
  zip_code NUMBER(38,0)
);



INSERT INTO RAW_DEV.TEST.CUSTOMERS (account_number, city, country, email, first_name, last_name, phone, state, street, zip_code)
  VALUES (1589420, 'san francisco', 'usa', 'john.doe@', 'john', 'doe', 1234567890, null, null, null);

INSERT INTO RAW_DEV.TEST.CUSTOMERS (account_number, city, country, email, first_name, last_name, phone, state, street, zip_code)
  VALUES (8028387, 'san francisco', 'usa', 'bart.simpson@example.com', 'bart', 'simpson', 1012023030, null, 'market st', 94102);

INSERT INTO RAW_DEV.TEST.CUSTOMERS (account_number, city, country, email, first_name, last_name, phone, state, street, zip_code)
  VALUES
    (1589420, 'san francisco', 'usa', 'john.doe@example.com', 'john', 'doe', 1234567890, 'ca', 'concar dr', 94402),
    (2834123, 'san mateo', 'usa', 'jane.doe@example.com', 'jane', 'doe', 3641252911, 'ca', 'concar dr', 94402),
    (4829381, 'san mateo', 'usa', 'jim.doe@example.com', 'jim', 'doe', 3641252912, 'ca', 'concar dr', 94402),
    (9821802, 'san francisco', 'usa', 'susan.smith@example.com', 'susan', 'smith', 1234567891, 'ca', 'geary st', 94121),
    (8028387, 'san francisco', 'usa', 'bart.simpson@example.com', 'bart', 'simpson', 1012023030, 'ca', 'market st', 94102);


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

SELECT TO_TIMESTAMP_TZ('2025-01-01')
;
UPDATE RAW_DEV.TEST.CUSTOMERS 
SET CREATED_AT = TO_TIMESTAMP_TZ('2025-01-01')

;

/*SET UP SCHEDILES */

  select * from RAW_DEV.TEST.CUSTOMERS ;

ALTER TABLE RAW_DEV.TEST.CUSTOMERS SET DATA_METRIC_SCHEDULE = '5 MINUTE';

  select * from RAW_DEV.TEST.employeesTable ; 

  ALTER TABLE RAW_DEV.TEST.employeesTable SET DATA_METRIC_SCHEDULE = '5 MINUTE';
  


  /* VIEW METRIC RESULTS */

  SELECT scheduled_time, measurement_time, table_name, metric_name, value
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS
WHERE TRUE
AND METRIC_NAME = 'INVALID_EMAIL_COUNT'
AND METRIC_DATABASE = 'DQ_TUTORIAL_DB'
LIMIT 100;



  /*CUSTOM - VALID E-MAIL ADDRESS */

CREATE DATA METRIC FUNCTION IF NOT EXISTS
invalid_email_count (ARG_T table(ARG_C1 STRING))
RETURNS NUMBER AS
'SELECT COUNT_IF(FALSE = (
ARG_C1 REGEXP ''^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$''))
FROM ARG_T'
;

ALTER TABLE RAW_DEV.TEST.CUSTOMERS  ADD DATA METRIC FUNCTION
invalid_email_count ON (email)

;

ALTER TABLE RAW_DEV.TEST.CUSTOMERS  MODIFY DATA METRIC FUNCTION
invalid_email_count ON (email)
ADD EXPECTATION my_exp (VALUE = 0);

;



  /*SYSTEM - FRESHNESS */
--Returns the difference in seconds between the maximum value of a timestamp column and the scheduled time when the data metric function runs.

SELECT SNOWFLAKE.CORE.FRESHNESS(
  SELECT
    created_at
  FROM RAW_DEV.TEST.CUSTOMERS ) < 300 ; ---last 300 seconds compared vs current timestamp using snowflake as reference. 

SNOWFLAKE.CORE.FRESHNESS(SELECT )

ALTER TABLE RAW_DEV.TEST.CUSTOMERS  add data metric function 
snowflake.core.freshness on (created_at) ;

ALTER TABLE RAW_DEV.TEST.CUSTOMERS  MODIFY data metric function 
snowflake.core.freshness on (created_at)
ADD EXPECTATION my_exp (VALUE < 300);



    /*SYSTEM - DUPLICATES */

SELECT SNOWFLAKE.CORE.DUPLICATE_COUNT(
  SELECT
    id
  FROM  RAW_DEV.TEST.employeesTable 
);

    
ALTER TABLE RAW_DEV.TEST.employeesTable  add data metric function 
snowflake.core.duplicate_count on (id)
;

ALTER TABLE RAW_DEV.TEST.employeesTable  MODIFY data metric function 
snowflake.core.duplicate_count on (id)
add expectation my_exp (VALUE = 0)
;



/* MONITORING TABLES */ 

--- MONITOR LATEST RESULTS
SELECT * FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS_RAW

;
SELECT * FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS WHERE TABLE_SCHEMA = 'TEST'

;
SELECT * FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_EXPECTATION_STATUS WHERE TABLE_SCHEMA = 'TEST'
;

/* Return all HISTORICAL  expectations for your Snowflake account */

SELECT * FROM snowflake.account_usage.data_metric_function_expectations
  ORDER BY expectation_name
  
  ;
  
/*IDENTIFY EXPECTATION OF SPECIFIC METRIC */
  SELECT expectation_name,
    ref_database_name as object_database,
    ref_schema_name as object_schema,
    ref_entity_name as object_name
  FROM snowflake.account_usage.data_metric_function_expectations
  WHERE
    metric_database_name = 'SNOWFLAKE' AND
    metric_schema_name = 'CORE' AND
    metric_name = 'ROW_COUNT'
  ORDER BY expectation_name;


  SHOW DATA METRIC FUNCTIONS IN ACCOUNT;

/*List DMFs associated with an object¶
*/
SELECT *
  FROM TABLE(
    INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
      REF_ENTITY_NAME => 'RAW_DEV.TEST.employeesTable',
      REF_ENTITY_DOMAIN => 'table'
    )
  );


  /*List objects associated with a DMF */

  USE DATABASE governance;
USE SCHEMA INFORMATION_SCHEMA;
SELECT *
  FROM TABLE(
    INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
      METRIC_NAME => 'snowflake.core.duplicate_count'
    )
  );


  use role accountadmin; 

  GRANT ROLE ORGADMIN TO USER "TONY.IMREK@CESYSTEMS.COM";