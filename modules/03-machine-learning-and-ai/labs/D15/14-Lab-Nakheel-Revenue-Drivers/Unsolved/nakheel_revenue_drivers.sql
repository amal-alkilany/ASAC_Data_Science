-- D15 · Lab 14 (optional, self-study) · What drove Nakheel's revenue up · Starter
-- Self-guided: run one statement at a time, after reading its step in the README.
-- The README explains each step: read it first, run the SQL, then compare with "What you should see".

-- Step 1 · Revenue by year, and what counts
SELECT IF(order_date >= DATE '2025-09-01', 'second year', 'first year') AS nakheel_year,
       COUNTIF(status = 'completed') AS completed_orders,
       ROUND(SUM(IF(status = 'completed', order_total, 0)), 2) AS completed_revenue,
       COUNTIF(status = 'pending') AS pending_orders
FROM nakheel.orders
GROUP BY nakheel_year
ORDER BY nakheel_year;

-- Step 2 · One row per order line, with its dimensions
CREATE OR REPLACE VIEW ml.revenue_lines AS
SELECT o.order_id,
       CASE
         WHEN c.customer_id IS NULL OR c.city IS NULL THEN 'unknown'
         WHEN LOWER(TRIM(c.city)) = 'al zarqa' THEN 'zarqa'
         ELSE LOWER(TRIM(c.city))
       END AS city,
       o.channel,
       IFNULL(LOWER(TRIM(c.segment)), 'unknown') AS segment,
       p.category,
       i.qty,
       i.qty * i.price AS item_revenue,
       o.order_date >= DATE '2025-09-01' AS is_test
FROM nakheel.orders AS o
JOIN nakheel.order_items AS i ON i.order_id = o.order_id
JOIN nakheel.products AS p ON p.product_id = i.product_id
LEFT JOIN nakheel.customers AS c ON c.customer_id = o.customer_id
WHERE o.status = 'completed';

SELECT is_test, COUNT(*) AS order_lines, ROUND(SUM(item_revenue), 2) AS line_revenue,
       COUNTIF(city = 'unknown') AS lines_city_unknown,
       COUNTIF(segment = 'unknown') AS lines_segment_unknown
FROM ml.revenue_lines
GROUP BY is_test
ORDER BY is_test;

-- Step 3 · The first model: a sum, four dimensions
CREATE OR REPLACE MODEL ml.revenue_drivers
OPTIONS (MODEL_TYPE = 'CONTRIBUTION_ANALYSIS',
         CONTRIBUTION_METRIC = 'SUM(item_revenue)',
         IS_TEST_COL = 'is_test',
         DIMENSION_ID_COLS = ['city', 'channel', 'segment', 'category']) AS
SELECT city, channel, segment, category, item_revenue, is_test
FROM ml.revenue_lines;

-- Step 4 · ML.GET_INSIGHTS: read the segments
SELECT contributors, metric_test, metric_control, difference,
       ROUND(relative_difference, 3) AS relative_difference,
       ROUND(unexpected_difference, 2) AS unexpected_difference,
       ROUND(relative_unexpected_difference, 3) AS relative_unexpected_difference,
       ROUND(apriori_support, 3) AS apriori_support, contribution
FROM ML.GET_INSIGHTS(MODEL ml.revenue_drivers)
ORDER BY contribution DESC;

-- Step 5 · unexpected_difference, by hand
WITH by_channel AS (
  SELECT channel,
         SUM(IF(is_test, item_revenue, 0)) AS second_year,
         SUM(IF(NOT is_test, item_revenue, 0)) AS first_year
  FROM ml.revenue_lines
  GROUP BY channel
),
totals AS (
  SELECT SUM(second_year) AS all_second_year, SUM(first_year) AS all_first_year
  FROM by_channel
)
SELECT channel, second_year, first_year,
       ROUND(first_year * (all_second_year - second_year) / (all_first_year - first_year), 2) AS expected_second_year,
       ROUND(second_year - first_year * (all_second_year - second_year) / (all_first_year - first_year), 2) AS unexpected_difference,
       ROUND(GREATEST(second_year / all_second_year, first_year / all_first_year), 4) AS apriori_support
FROM by_channel
CROSS JOIN totals
ORDER BY channel;

-- Step 6 · Check with plain SQL: the change by city, channel, segment and category
SELECT 'city' AS dimension, city AS dimension_value,
       ROUND(SUM(IF(NOT is_test, item_revenue, 0)), 2) AS first_year,
       ROUND(SUM(IF(is_test, item_revenue, 0)), 2) AS second_year,
       ROUND(SUM(IF(is_test, item_revenue, -item_revenue)), 2) AS change_in_revenue
FROM ml.revenue_lines GROUP BY city
UNION ALL
SELECT 'channel', channel,
       ROUND(SUM(IF(NOT is_test, item_revenue, 0)), 2), ROUND(SUM(IF(is_test, item_revenue, 0)), 2),
       ROUND(SUM(IF(is_test, item_revenue, -item_revenue)), 2)
FROM ml.revenue_lines GROUP BY channel
UNION ALL
SELECT 'segment', segment,
       ROUND(SUM(IF(NOT is_test, item_revenue, 0)), 2), ROUND(SUM(IF(is_test, item_revenue, 0)), 2),
       ROUND(SUM(IF(is_test, item_revenue, -item_revenue)), 2)
FROM ml.revenue_lines GROUP BY segment
UNION ALL
SELECT 'category', category,
       ROUND(SUM(IF(NOT is_test, item_revenue, 0)), 2), ROUND(SUM(IF(is_test, item_revenue, 0)), 2),
       ROUND(SUM(IF(is_test, item_revenue, -item_revenue)), 2)
FROM ml.revenue_lines GROUP BY category
ORDER BY dimension, change_in_revenue DESC;

-- Step 7 · DIMENSION_ID_COLS: fewer dimensions, or left out
CREATE OR REPLACE MODEL ml.revenue_drivers_city_channel
OPTIONS (MODEL_TYPE = 'CONTRIBUTION_ANALYSIS',
         CONTRIBUTION_METRIC = 'SUM(item_revenue)',
         IS_TEST_COL = 'is_test') AS
SELECT city, channel, item_revenue, is_test
FROM ml.revenue_lines;

SELECT contributors, difference, ROUND(unexpected_difference, 2) AS unexpected_difference,
       ROUND(apriori_support, 3) AS apriori_support
FROM ML.GET_INSIGHTS(MODEL ml.revenue_drivers_city_channel)
ORDER BY contribution DESC;

-- Step 8 · MIN_APRIORI_SUPPORT: how small a segment may be
CREATE OR REPLACE MODEL ml.revenue_drivers_05
OPTIONS (MODEL_TYPE = 'CONTRIBUTION_ANALYSIS',
         CONTRIBUTION_METRIC = 'SUM(item_revenue)',
         IS_TEST_COL = 'is_test',
         DIMENSION_ID_COLS = ['city', 'channel', 'segment', 'category'],
         MIN_APRIORI_SUPPORT = 0.05) AS
SELECT city, channel, segment, category, item_revenue, is_test
FROM ml.revenue_lines;

SELECT contributors, difference, ROUND(apriori_support, 4) AS apriori_support
FROM ML.GET_INSIGHTS(MODEL ml.revenue_drivers_05)
WHERE apriori_support < 0.1
ORDER BY contribution DESC
LIMIT 5;

-- Step 9 · TOP_K_INSIGHTS_BY_APRIORI_SUPPORT: keep the k largest segments
CREATE OR REPLACE MODEL ml.revenue_drivers_top10
OPTIONS (MODEL_TYPE = 'CONTRIBUTION_ANALYSIS',
         CONTRIBUTION_METRIC = 'SUM(item_revenue)',
         IS_TEST_COL = 'is_test',
         DIMENSION_ID_COLS = ['city', 'channel', 'segment', 'category'],
         TOP_K_INSIGHTS_BY_APRIORI_SUPPORT = 10) AS
SELECT city, channel, segment, category, item_revenue, is_test
FROM ml.revenue_lines;

SELECT contributors, difference, ROUND(apriori_support, 3) AS apriori_support
FROM ML.GET_INSIGHTS(MODEL ml.revenue_drivers_top10)
ORDER BY apriori_support DESC;

-- Step 10 · PRUNING_METHOD: drop rows that repeat another row
CREATE OR REPLACE MODEL ml.revenue_drivers_pruned
OPTIONS (MODEL_TYPE = 'CONTRIBUTION_ANALYSIS',
         CONTRIBUTION_METRIC = 'SUM(item_revenue)',
         IS_TEST_COL = 'is_test',
         DIMENSION_ID_COLS = ['city', 'channel', 'segment', 'category'],
         PRUNING_METHOD = 'PRUNE_REDUNDANT_INSIGHTS') AS
SELECT city, channel, segment, category, item_revenue, is_test
FROM ml.revenue_lines;

SELECT 'no pruning' AS pruning, COUNT(*) AS insights FROM ML.GET_INSIGHTS(MODEL ml.revenue_drivers)
UNION ALL
SELECT 'prune redundant', COUNT(*) FROM ML.GET_INSIGHTS(MODEL ml.revenue_drivers_pruned);

-- Step 11 · CONTRIBUTION_METRIC as a ratio: revenue per unit sold
CREATE OR REPLACE MODEL ml.revenue_per_unit
OPTIONS (MODEL_TYPE = 'CONTRIBUTION_ANALYSIS',
         CONTRIBUTION_METRIC = 'SUM(item_revenue)/SUM(qty)',
         IS_TEST_COL = 'is_test',
         DIMENSION_ID_COLS = ['city', 'channel', 'segment', 'category']) AS
SELECT city, channel, segment, category, item_revenue, qty, is_test
FROM ml.revenue_lines;

SELECT contributors, ROUND(metric_test, 2) AS metric_test, ROUND(metric_control, 2) AS metric_control,
       ROUND(metric_test_over_metric_control, 3) AS metric_test_over_metric_control,
       ROUND(aumann_shapley_attribution, 3) AS aumann_shapley_attribution,
       ROUND(apriori_support, 3) AS apriori_support
FROM ML.GET_INSIGHTS(MODEL ml.revenue_per_unit)
ORDER BY contribution DESC
LIMIT 10;

SELECT is_test, SUM(qty) AS units_sold, ROUND(SUM(item_revenue) / SUM(qty), 2) AS revenue_per_unit
FROM ml.revenue_lines
GROUP BY is_test
ORDER BY is_test;

-- Step 12 · CONTRIBUTION_METRIC per category: revenue per order
CREATE OR REPLACE MODEL ml.revenue_per_order
OPTIONS (MODEL_TYPE = 'CONTRIBUTION_ANALYSIS',
         CONTRIBUTION_METRIC = 'SUM(item_revenue)/COUNT(DISTINCT order_id)',
         IS_TEST_COL = 'is_test',
         DIMENSION_ID_COLS = ['city', 'channel', 'segment', 'category']) AS
SELECT city, channel, segment, category, item_revenue, order_id, is_test
FROM ml.revenue_lines;

SELECT contributors, ROUND(metric_test, 2) AS metric_test, ROUND(metric_control, 2) AS metric_control,
       ROUND(difference, 2) AS difference, ROUND(relative_difference, 3) AS relative_difference,
       ROUND(apriori_support, 3) AS apriori_support
FROM ML.GET_INSIGHTS(MODEL ml.revenue_per_order)
ORDER BY contribution DESC
LIMIT 10;

SELECT is_test, COUNT(DISTINCT order_id) AS orders_completed,
       ROUND(SUM(item_revenue) / COUNT(DISTINCT order_id), 2) AS revenue_per_order
FROM ml.revenue_lines
GROUP BY is_test
ORDER BY is_test;
