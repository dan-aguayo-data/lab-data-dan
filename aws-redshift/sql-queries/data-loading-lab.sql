DROP TABLE IF EXISTS part;
DROP TABLE IF EXISTS supplier;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS dwdate;
DROP TABLE IF EXISTS lineorder;

CREATE TABLE part (
  p_partkey     INTEGER NOT NULL,
  p_name        VARCHAR(22) NOT NULL,
  p_mfgr        VARCHAR(6),
  p_category    VARCHAR(7) NOT NULL,
  p_brand1      VARCHAR(9) NOT NULL,
  p_color       VARCHAR(11) NOT NULL,
  p_type        VARCHAR(25) NOT NULL,
  p_size        INTEGER NOT NULL,
  p_container   VARCHAR(10) NOT NULL
);

CREATE TABLE supplier (
  s_suppkey   INTEGER NOT NULL,
  s_name      VARCHAR(25) NOT NULL,
  s_address   VARCHAR(25) NOT NULL,
  s_city      VARCHAR(10) NOT NULL,
  s_nation    VARCHAR(15) NOT NULL,
  s_region    VARCHAR(12) NOT NULL,
  s_phone     VARCHAR(15) NOT NULL
);

CREATE TABLE customer (
  c_custkey      INTEGER NOT NULL,
  c_name         VARCHAR(25) NOT NULL,
  c_address      VARCHAR(25) NOT NULL,
  c_city         VARCHAR(10) NOT NULL,
  c_nation       VARCHAR(15) NOT NULL,
  c_region       VARCHAR(12) NOT NULL,
  c_phone        VARCHAR(15) NOT NULL,
  c_mktsegment   VARCHAR(10) NOT NULL
);

CREATE TABLE dwdate (
  d_datekey            INTEGER NOT NULL,
  d_date               VARCHAR(19) NOT NULL,
  d_dayofweek          VARCHAR(10) NOT NULL,
  d_month              VARCHAR(10) NOT NULL,
  d_year               INTEGER NOT NULL,
  d_yearmonthnum       INTEGER NOT NULL,
  d_yearmonth          VARCHAR(8) NOT NULL,
  d_daynuminweek       INTEGER NOT NULL,
  d_daynuminmonth      INTEGER NOT NULL,
  d_daynuminyear       INTEGER NOT NULL,
  d_monthnuminyear     INTEGER NOT NULL,
  d_weeknuminyear      INTEGER NOT NULL,
  d_sellingseason      VARCHAR(13) NOT NULL,
  d_lastdayinweekfl    VARCHAR(1) NOT NULL,
  d_lastdayinmonthfl   VARCHAR(1) NOT NULL,
  d_holidayfl          VARCHAR(1) NOT NULL,
  d_weekdayfl          VARCHAR(1) NOT NULL
);

CREATE TABLE lineorder (
  lo_orderkey          INTEGER NOT NULL,
  lo_linenumber        INTEGER NOT NULL,
  lo_custkey           INTEGER NOT NULL,
  lo_partkey           INTEGER NOT NULL,
  lo_suppkey           INTEGER NOT NULL,
  lo_orderdate         INTEGER NOT NULL,
  lo_orderpriority     VARCHAR(15) NOT NULL,
  lo_shippriority      VARCHAR(1) NOT NULL,
  lo_quantity          INTEGER NOT NULL,
  lo_extendedprice     INTEGER NOT NULL,
  lo_ordertotalprice   INTEGER NOT NULL,
  lo_discount          INTEGER NOT NULL,
  lo_revenue           INTEGER NOT NULL,
  lo_supplycost        INTEGER NOT NULL,
  lo_tax               INTEGER NOT NULL,
  lo_commitdate        INTEGER NOT NULL,
  lo_shipmode          VARCHAR(10) NOT NULL
);

-- Confirm table creation
SELECT DISTINCT(tablename) FROM pg_table_def WHERE schemaname = 'public';

-- Set slot count
SET wlm_query_slot_count TO 2;

-- Sample copy (will fail)
COPY part
FROM 's3://richmorrow-5280/'
CREDENTIALS '<REDACTED>'
;

-- Sample copy (will succeed)
COPY part
FROM 's3://richmorrow-5280/data-load/part-csv.tbl'
CREDENTIALS '<REDACTED>'
CSV
NULL AS '\000';

-- Load error diagnostics
SELECT query, SUBSTRING(filename,22,25) AS filename, line_number AS line, 
SUBSTRING(colname,0,12) AS column, type, position AS pos, 
SUBSTRING(raw_line,0,30) AS line_text,
SUBSTRING(raw_field_value,0,15) AS field_text, 
SUBSTRING(err_reason,0,45) AS reason
FROM stl_load_errors 
ORDER BY query DESC
LIMIT 10;

-- Load supplier
COPY supplier
FROM 's3://awssampledbuswest2/ssbgz/supplier.tbl'
CREDENTIALS '<REDACTED>'
DELIMITER '|'
GZIP
REGION 'us-west-2';

-- Load fixed-width customer (this will fail due to data issues)
COPY customer
FROM 's3://richmorrow-5280/data-load/customer-fw.tbl'
CREDENTIALS '<REDACTED>'
FIXEDWIDTH 'c_custkey:10, c_name:25, c_address:25, c_city:10, c_nation:15, c_region:12, c_phone:15, c_mktsegment:10';

-- Retry with maxerror
COPY customer
FROM 's3://richmorrow-5280/data-load/customer-fw.tbl'
CREDENTIALS '<REDACTED>'
FIXEDWIDTH 'c_custkey:10, c_name:25, c_address:25, c_city:10, c_nation:15, c_region:12, c_phone:15, c_mktsegment:10'
MAXERROR 10;

-- Load using manifest
COPY customer
FROM 's3://richmorrow-5280/data-load/customer-fw-manifest'
CREDENTIALS '<REDACTED>'
FIXEDWIDTH 'c_custkey:10, c_name:25, c_address:25, c_city:10, c_nation:15, c_region:12, c_phone:15, c_mktsegment:10'
MAXERROR 10
ACCEPTINVCHARS AS '^'
MANIFEST;

-- Count validation
SELECT COUNT(*) FROM customer;
SELECT COUNT(*) FROM dwdate;
SELECT COUNT(*) FROM lineorder;
SELECT COUNT(*) FROM part;
SELECT COUNT(*) FROM supplier;

-- Cleanup
DELETE FROM customer;
DELETE FROM part;
DELETE FROM supplier;

-- Reload data
COPY dwdate FROM 's3://awssampledbuswest2/ssbgz/dwdate'
CREDENTIALS '<REDACTED>'
GZIP
COMPUPDATE OFF;

COPY part FROM 's3://awssampledbuswest2/ssbgz/part'
CREDENTIALS '<REDACTED>'
GZIP
COMPUPDATE OFF;

COPY supplier FROM 's3://awssampledbuswest2/ssbgz/supplier'
CREDENTIALS '<REDACTED>'
GZIP
COMPUPDATE OFF;

COPY customer FROM 's3://awssampledbuswest2/ssbgz/customer'
CREDENTIALS '<REDACTED>'
GZIP
COMPUPDATE OFF;

COPY lineorder FROM 's3://awssampledbuswest2/ssbgz/lineorder'
CREDENTIALS '<REDACTED>'
GZIP
COMPUPDATE OFF;

-- Check load commits
SELECT query, TRIM(filename) AS file, curtime AS updated
FROM stl_load_commits
ORDER BY updated DESC;

-- Check disk usage
SELECT slice, col, num_values, minvalue, maxvalue
FROM svv_diskusage
WHERE name='customer' AND col=0
ORDER BY slice, col;

-- Check for disk spills
SELECT query, step, rows, workmem, label, is_diskbased
FROM svl_query_summary
WHERE query = [YOUR-QUERY-ID]
ORDER BY workmem DESC;

-- Check table structure
SELECT "column", type, encoding, distkey, sortkey, "notnull" 
FROM pg_table_def
WHERE tablename = 'lineorder';
