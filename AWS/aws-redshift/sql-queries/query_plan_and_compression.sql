

--- QUEY PERFORMANCE

SET enable_result_cache_for_session TO OFF;

--EXPLAIN QUERY PLAN
EXPLAIN
SELECT
  aircraft,
  SUM(departures) AS trips
FROM flights
JOIN aircraft using (aircraft_code)
GROUP BY aircraft
ORDER BY trips DESC
LIMIT 10;



-- COMPRESSION IN TABLES

ANALYZE COMPRESSION flights;


---TYPES OF COMPRESSION

--Byte dictionary: A method of reference up to 256 possible values in a single byte. Ideal for fields with few, but frequently repeated, values such as Country names.
--Delta: Compresses data by recording the difference between values that follow each other in the column.
--LZO: Provides a very high compression ratio with good performance. Works well for columns that store very long character strings, especially free form text, such as product descriptions, user comments, or JSON strings.
--Mostly: Compresses the majority of the values in the column to a smaller standard storage size.
--Run-length: Replaces a value that is repeated consecutively with a token that consists of the value and a count of the number of consecutive occurrences (the length of the run). Best suited to a table in which data values are often repeated consecutively, for example, when the table is sorted by those values.
--Text: Compresses VARCHAR columns in which the same words recur often.
--Zstandard: (zstd) Provides a high compression ratio with very good performance across diverse data sets. Works especially well with CHAR and VARCHAR columns that store a wide range of long and short strings, such as product descriptions, user comments, logs, and JSON strings.
--AZ64 AZ64 is a proprietary compression encoding algorithm designed by Amazon to achieve a high compression ratio and improved query processing.
--Raw: Uncompressed



