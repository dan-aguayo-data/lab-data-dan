--- CREATE FACT TABLE AND DIMENSION + COPYING CSV FROM S3

CREATE TABLE flights (
  year           smallint,
  month          smallint,
  day            smallint,
  carrier        varchar(80) DISTKEY,
  origin         char(3),
  dest           char(3),
  aircraft_code  char(3),
  miles          int,
  departures     int,
  minutes        int,
  seats          int,
  passengers     int,
  freight_pounds int
);



COPY flights
FROM 's3://us-west-2-aws-training/courses/spl-17/v4.2.17.prod-287e4e43/data/flights-usa'
IAM_ROLE 'arn:aws:iame'
GZIP
DELIMITER ','
REMOVEQUOTES
REGION 'us-west-2';



SELECT COUNT(*) FROM flights;

SELECT *
FROM flights
ORDER BY random()
LIMIT 10;



SELECT
  carrier,
  SUM (departures)
FROM flights
GROUP BY carrier
ORDER BY 2 DESC
LIMIT 10;


CREATE TABLE aircraft (
  aircraft_code CHAR(3) SORTKEY,
  aircraft      VARCHAR(100)
);


COPY aircraft
FROM 's3://us-west-2-aws-training/courses/spl-17/v4.2.17.prod-287e4e43/data/lookup_aircraft.csv'
IAM_ROLE 'arn:aws:iame'
IGNOREHEADER 1
DELIMITER ','
REMOVEQUOTES
TRUNCATECOLUMNS
REGION 'us-west-2';



SELECT *
FROM aircraft
ORDER BY random()
LIMIT 10;



SELECT
  aircraft,
  SUM(departures) AS trips
FROM flights
JOIN aircraft using (aircraft_code)
GROUP BY aircraft
ORDER BY trips DESC
LIMIT 10;

