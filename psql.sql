-- find sizes of all databases
SELECT 
  datname, 
  pg_size_pretty(pg_database_size(datname))
FROM pg_database
ORDER BY pg_database_size(datname) DESC
;


-- cache hit rate should not be lower that 99%, if so perhaps we will need to increase available memory.
SELECT 
  sum(heap_blks_read) AS heap_read, 
  sum(heap_blks_hit)  AS heap_hit, 
  abs(sum(heap_blks_read) - sum(heap_blks_hit)) / sum(heap_blks_hit) AS ratio
FROM pg_statio_user_tables
;


-- table index usage rates (should not be less than 0.99)
SELECT 
  relname, 
  100 * idx_scan / (seq_scan + idx_scan) percent_of_times_index_used, n_live_tup rows_in_table
FROM pg_stat_user_tables 
ORDER BY n_live_tup DESC
;


-- how many indexes are in cache
SELECT 
  sum(idx_blks_read) AS idx_read, 
  sum(idx_blks_hit)  AS idx_hit, 
  (sum(idx_blks_hit) - sum(idx_blks_read)) / sum(idx_blks_hit) AS ratio
FROM pg_statio_user_indexes
;


-- find those space grobbling useless indexes.
SELECT
  indexrelid::regclass AS index,
  relid::regclass AS table,
  'DROP INDEX ' || indexrelid::regclass || ';' as drop_statement
FROM pg_stat_user_indexes
JOIN pg_index USING (indexrelid)
WHERE idx_scan = 0
  AND indisunique is false
;


-- function to determine the speed of query, pass the nuber of iterations desired and the query in question as a string
-- note that statistics may fudge up results slightly.
CREATE OR REPLACE FUNCTION queryRunTime (n integer, expression varchar)
  RETURNS DOUBLE PRECISION AS $$
DECLARE
  totalTime NUMERIC(10, 3) := 0;
  iteration INTEGER := 0 ;
  StartTime timestamptz;
  EndTime timestamptz;
  trash integer;
BEGIN

  WHILE iteration < n LOOP
    iteration := iteration + 1;
    StartTime := clock_timestamp();

    execute expression;

    EndTime := clock_timestamp();
    totalTime := totalTime + 1000 * (extract(epoch from EndTime) - extract(epoch from StartTime));
  END LOOP ;

  RETURN totalTime ;
END ;
$$ LANGUAGE plpgsql;


-- find tables with more seq scans than index scans. Not a panacea but useful.
SELECT
  relname,
  seq_scan - idx_scan AS too_much_seq,
  CASE
    WHEN seq_scan - idx_scan > 0 THEN 'Missing Index?'
    ELSE 'OK'
  END,
  pg_relation_size(relname::regclass) AS rel_size, 
  seq_scan, 
  idx_scan
FROM pg_stat_all_tables
WHERE schemaname = 'public'
  AND pg_relation_size(relname::regclass) > 80000
ORDER BY too_much_seq DESC
;

-- change data type of coumn
ALTER TABLE customers ALTER COLUMN customer_id TYPE integer USING customer_id::[DATATYPE];
