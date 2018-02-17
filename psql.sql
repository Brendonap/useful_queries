-- find sizes of all databases
select 
  datname, 
  pg_size_pretty(pg_database_size(datname))
from pg_database
order by pg_database_size(datname) desc
;

-- cache hit rate should not be lower that 99%, if so perhaps we will need to increase available memory.
SELECT 
  sum(heap_blks_read) as heap_read, 
  sum(heap_blks_hit)  as heap_hit, 
  abs(sum(heap_blks_read) - sum(heap_blks_hit)) / sum(heap_blks_hit) as ratio
FROM pg_statio_user_tables
;