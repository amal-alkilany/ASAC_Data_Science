-- D10 · 5.2 Everyone Do: Query a file where it lives
-- Runs in BigQuery only (Cloud Storage); not part of the DuckDB check.

-- 1. A dataset for files.
-- @skip
CREATE SCHEMA IF NOT EXISTS files
OPTIONS (location = 'US');

-- 2. The external table.
-- @skip
CREATE OR REPLACE EXTERNAL TABLE files.us_states (
  name STRING,
  post_abbr STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://cloud-samples-data/bigquery/us-states/us-states.csv'],
  skip_leading_rows = 1
);

-- 4. States starting with W. (4 rows: Washington, West Virginia, Wisconsin, Wyoming)
-- @skip
SELECT name, post_abbr
FROM files.us_states
WHERE name LIKE 'W%'
ORDER BY name;

-- 5. The file behind the rows. (1 row: the gs:// address, 50)
-- @skip
SELECT _FILE_NAME AS source_file,
       COUNT(*) AS states
FROM files.us_states
GROUP BY source_file;
