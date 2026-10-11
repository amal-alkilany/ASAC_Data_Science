-- D10 · After class: What the sandbox shows, and what needs billing
-- INFORMATION_SCHEMA is BigQuery's; the DuckDB check skips these.

-- 3. The tables in a dataset. (4 rows, each a BASE TABLE; try bi for the views)
-- @skip
SELECT table_name, table_type, creation_time
FROM nakheel.INFORMATION_SCHEMA.TABLES
ORDER BY table_name;

-- 3, columns. The columns of one table. (9 rows; order_id first)
-- @skip
SELECT column_name, data_type
FROM nakheel.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'orders'
ORDER BY ordinal_position;
