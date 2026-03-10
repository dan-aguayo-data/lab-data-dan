

--CREATE TABLE WITH SORTKEY

CREATE TABLE airports (
  airport_code CHAR(3) SORTKEY,
  airport      varchar(100)
);


COPY airports
FROM 's3://us-west-2-aws-training/courses/spl-17/v4.2.17.prod-287e4e43/data/lookup_airports.csv'
IAM_ROLE 'arn:aws:iamRedshift-Role'
IGNOREHEADER 1
DELIMITER ','
REMOVEQUOTES
TRUNCATECOLUMNS
REGION 'us-west-2';


---CREATE TABLES FROM OTHER


CREATE TABLE vegas_flights
  DISTKEY (origin)
  SORTKEY (origin)
AS
SELECT
  flights.*,
  airport
FROM flights
JOIN airports ON origin = airport_code
WHERE dest = 'LAS';


SELECT
  airport,
  to_char(SUM(passengers), '999,999,999') as passengers
FROM vegas_flights
GROUP BY airport
ORDER BY SUM(passengers) desc
LIMIT 10;




