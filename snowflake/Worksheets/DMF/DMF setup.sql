/* GRANT PERMISSIONS TO ROLE */

USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS CES_DATA_DQ;

GRANT EXECUTE DATA METRIC FUNCTION ON ACCOUNT TO ROLE CES_DATA_DQ;
GRANT APPLICATION ROLE SNOWFLAKE.DATA_QUALITY_MONITORING_VIEWER TO ROLE CES_DATA_DQ;
GRANT DATABASE ROLE SNOWFLAKE.USAGE_VIEWER TO ROLE CES_DATA_DQ;
GRANT DATABASE ROLE SNOWFLAKE.DATA_METRIC_USER TO ROLE CES_DATA_DQ;




GRANT USAGE ON WAREHOUSE ANALYTICS_CES TO ROLE CES_DATA_DQ;
SHOW GRANTS TO ROLE CES_DATA_DQ;

/*Establish a role hierarchy and grant the role to a user who can complete this tutorial*/
GRANT ROLE CES_DATA_DQ TO ROLE SYSADMIN;


USE ROLE SYSADMIN;


CREATE TABLE RAW_DEV.TEST.CUSTOMERS (
  account_number NUMBER(38,0),
  first_name VARCHAR(16777216),
  last_name VARCHAR(16777216),
  email VARCHAR(16777216),
  phone VARCHAR(16777216),
  created_at TIMESTAMP_NTZ(9),
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


SELECT * FROM RAW_DEV.TEST.CUSTOMERS  ;

-- return the number of email addresses in a column that don’t match the specified regular expression:

USE DATABASE RAW_DEV;
USE SCHEMA TEST;


/* CREATE FUNCTION */

CREATE DATA METRIC FUNCTION IF NOT EXISTS
  invalid_email_count (ARG_T table(ARG_C1 STRING))
  RETURNS NUMBER AS
  'SELECT COUNT_IF(FALSE = (
    ARG_C1 REGEXP ''^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$''))
    FROM ARG_T';


    /* CREATE SCHEDULE */

    
ALTER TABLE RAW_DEV.TEST.CUSTOMERS SET DATA_METRIC_SCHEDULE = '5 MINUTE';

--other schedule settings, such as cron expressions or trigger events associated with DML operations that affect the table.


/* ADD METRIC TO TABLE */

ALTER TABLE RAW_DEV.TEST.CUSTOMERS  ADD DATA METRIC FUNCTION
  invalid_email_count ON (email);


/* CHECK ASSOCIATED METRICS TO TABLES */

  SELECT * FROM TABLE(INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
  REF_ENTITY_NAME => 'RAW_DEV.TEST.CUSTOMERS',
  REF_ENTITY_DOMAIN => 'TABLE'));


  /* VIEW METRIC RESULTS */

  SELECT scheduled_time, measurement_time, table_name, metric_name, value
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS
WHERE TRUE
AND METRIC_NAME = 'INVALID_EMAIL_COUNT'
AND METRIC_DATABASE = 'DQ_TUTORIAL_DB'
LIMIT 100;


--UNSET METRIC FROM TABLE 


ALTER TABLE customers DROP DATA METRIC FUNCTION
  invalid_email_count ON (email);


  ; 
-- SEE METRIC FUNCTIONS AVAILABLE
  SELECT * FROM RAW_DEV.INFORMATION_SCHEMA.FUNCTIONS