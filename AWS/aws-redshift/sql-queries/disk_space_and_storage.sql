--QUERIES TO ASSESS PERFORMANCE OF ENVIRONMENT


--- DISK SHOULDN'T FLUCTUATE ABOVE 85%

--This query shows how much of each disk/node is used.

SELECT
  owner AS node,
  diskno,
  used,
  capacity,
  used/capacity::numeric * 100 as percent_used
FROM stv_partitions
WHERE host = node
ORDER BY 1, 2;



--STORAGE SPACE BY TABLE
--HOW MANY DISK BLOCKS EACH TABLE IS USING, EACH BLOCK - 1MB

SELECT
  name,
  count(*)
FROM stv_blocklist
JOIN (SELECT DISTINCT name, id as tbl from stv_tbl_perm) USING (tbl)
GROUP BY name;



