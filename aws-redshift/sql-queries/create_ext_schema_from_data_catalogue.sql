--Query 1: Retrieve data from the players_data table and sort by game_details 

SELECT * FROM "games-flattened-data-db"."players_data"
ORDER BY game_details;


--Query 2: Retrieve data from the games_data table and sort by id and index

SELECT * FROM "games-flattened-data-db"."games_data"
ORDER BY id, index;


--Query 3: Create external schema in Amazon Redshift

create EXTERNAL SCHEMA players_schema
FROM DATA CATALOG
database 'games-flattened-data-db'
IAM_ROLE 'ENTER YOUR IAM ROLE ARN ASSOCIATED WITH AMAZON REDSHIFT'
create EXTERNAL DATABASE if not exists;


--Query 4: Retrieve data from the players_data table and sort by game_details 

SELECT * FROM players_schema.players_data
ORDER BY game_details;


--Query 5: Retrieve data from the games_data table and sort by id and index

SELECT * FROM players_schema.games_data
ORDER BY id, index;


--Query 6: Find the purchases by the player with ID 12345

SELECT g.id as Id, p.name as Name, g.purchased_item as Purchased_item, '$'||g.purchases as Purchases
FROM players_schema.players_data p, players_schema.games_data g
WHERE p.game_details = g.id AND g.id='12345'; 


--Query 7: Create a materialized view

DROP MATERIALIZED VIEW IF EXISTS mv_players_purchases;
CREATE MATERIALIZED VIEW mv_players_purchases AS (
SELECT g.id as Id, p.name as Name, g.purchased_item as Purchased_item, '$'||g.purchases as Purchases
FROM players_schema.players_data p, players_schema.games_data g
WHERE p.game_details = g.id); 


--Query 8: Find the purchases by the player with ID 12345 using a materialized view

SELECT * FROM mv_players_purchases
WHERE id='12345';


DIY: Hints
