-- D10 · 5.3 Instructor Do: Read less: partitions and clusters
-- BigQuery only. Partitioning and clustering do not exist in the DuckDB check, so every
-- statement except the last is skipped there. In class, read the bytes estimates; do not run.

-- 4. The shape of the DDL: orders split by month, sorted by channel inside each month.
--    Do NOT run this in the sandbox: partitions there expire 60 days after their date,
--    and Nakheel ends on 31 August 2026 (step 8).
-- @skip BigQuery only; never in the sandbox
CREATE TABLE nakheel.orders_partitioned
PARTITION BY DATE_TRUNC(order_date, MONTH)
CLUSTER BY channel
AS
SELECT *
FROM nakheel.orders;

-- 7. A public table that is already partitioned, by refresh_date. Type each query and read
--    the estimate in the top right of the editor. Do not run either.
--    With the filter: one day's partition.
-- @skip BigQuery only; public dataset, read the estimate only
SELECT term, rank
FROM `bigquery-public-data.google_trends.top_terms`
WHERE refresh_date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);

-- 7. Without the filter: every partition.
-- @skip BigQuery only; public dataset, read the estimate only
SELECT term, rank
FROM `bigquery-public-data.google_trends.top_terms`;

-- 9. Optional, after class: an integer-range copy of orders, which the 60-day rule does not touch.
--    order_month is a whole number such as 202604; one partition per number.
-- @skip BigQuery only; integer-range partitioning
CREATE OR REPLACE TABLE nakheel.orders_by_month
PARTITION BY RANGE_BUCKET(order_month, GENERATE_ARRAY(202409, 202609, 1))
CLUSTER BY channel
AS
SELECT *,
       EXTRACT(YEAR FROM order_date) * 100 + EXTRACT(MONTH FROM order_date) AS order_month
FROM nakheel.orders;

-- 9. Compare the two estimates: one month, then the whole table.
-- @skip BigQuery only; read the estimate
SELECT order_id, order_total
FROM nakheel.orders_by_month
WHERE order_month = 202604;

-- @skip BigQuery only; read the estimate
SELECT order_id, order_total
FROM nakheel.orders_by_month;

-- 9, months. What the partitions would hold: one row per month. Runs anywhere.
--    (24 rows; 202604 holds 144 of the 3,000 orders)
-- @check 9, months
SELECT EXTRACT(YEAR FROM order_date) * 100 + EXTRACT(MONTH FROM order_date) AS order_month,
       COUNT(*) AS orders
FROM nakheel.orders
GROUP BY order_month
ORDER BY order_month;
