-- D11 · Lab 08 (optional) · Nakheel: from raw tables to a model · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

-- Step 1 · Check the data
-- Orders: one row per order, three statuses.
SELECT status, COUNT(*) AS orders, COUNT(DISTINCT customer_id) AS customers
FROM nakheel.orders
GROUP BY status
ORDER BY status;

-- Segments as they were typed.
SELECT segment, COUNT(*) AS customers
FROM nakheel.customers
GROUP BY segment
ORDER BY customers DESC;

-- Cities as they were typed.
SELECT city, COUNT(*) AS customers
FROM nakheel.customers
GROUP BY city
ORDER BY customers DESC;

-- Step 3 · Build the customer view
CREATE SCHEMA IF NOT EXISTS ml OPTIONS (location = 'US');

CREATE OR REPLACE VIEW ml.customer_features AS
WITH customers AS (
  -- One meaning, one spelling; a missing city stays visible as 'unknown'.
  SELECT customer_id,
         LOWER(TRIM(segment)) AS segment,
         CASE
           WHEN city IS NULL THEN 'unknown'
           WHEN LOWER(TRIM(city)) = 'al zarqa' THEN 'zarqa'
           ELSE LOWER(TRIM(city))
         END AS city,
         signup_date
  FROM nakheel.customers
),
before_cutoff AS (
  -- Features: completed orders before 1 March, one row per customer.
  SELECT customer_id,
         COUNT(*) AS orders_before,
         ROUND(SUM(order_total), 2) AS revenue_before,
         MAX(order_date) AS last_order_before,
         ROUND(AVG(IF(channel = 'online', 1, 0)), 3) AS online_share
  FROM nakheel.orders
  WHERE status = 'completed'
    AND order_date < DATE '2026-03-01'
  GROUP BY customer_id
),
after_cutoff AS (
  -- The label: completed spend from 1 March to 31 August. Never a feature.
  SELECT customer_id,
         ROUND(SUM(order_total), 2) AS revenue_next_6m
  FROM nakheel.orders
  WHERE status = 'completed'
    AND order_date >= DATE '2026-03-01'
    AND order_date <  DATE '2026-09-01'
  GROUP BY customer_id
)
SELECT c.customer_id,
       c.segment,
       c.city,
       b.orders_before,
       b.revenue_before,
       ROUND(b.revenue_before / b.orders_before, 2) AS avg_order_value,
       DATE_DIFF(DATE '2026-03-01', b.last_order_before, DAY) AS days_since_last,
       DATE_DIFF(DATE '2026-03-01', c.signup_date, DAY) AS tenure_days,
       b.online_share,
       COALESCE(a.revenue_next_6m, 0) AS revenue_next_6m
FROM customers AS c
INNER JOIN before_cutoff AS b ON c.customer_id = b.customer_id
LEFT JOIN after_cutoff AS a ON c.customer_id = a.customer_id;

SELECT COUNT(*) AS customers,
       COUNTIF(revenue_next_6m = 0) AS bought_nothing_after,
       ROUND(AVG(revenue_next_6m), 2) AS avg_next_6m
FROM ml.customer_features;

-- Step 4 · Train, with the split chosen on purpose
CREATE OR REPLACE MODEL ml.spend_model
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['revenue_next_6m'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2) AS
SELECT segment, city, orders_before, revenue_before, avg_order_value,
       days_since_last, tenure_days, online_share,
       revenue_next_6m
FROM ml.customer_features;

-- Step 5 · Score it, and compare it with a guess
SELECT ROUND(mean_absolute_error, 2) AS mae, ROUND(r2_score, 3) AS r2
FROM ML.EVALUATE(MODEL ml.spend_model);

SELECT ROUND(AVG(ABS(revenue_next_6m - 220.51)), 2) AS mae_of_the_average_guess
FROM ml.customer_features;

-- Step 6 · Look at what it does wrong
SELECT customer_id, segment, revenue_before, revenue_next_6m,
       ROUND(predicted_revenue_next_6m, 2) AS predicted
FROM ML.PREDICT(MODEL ml.spend_model, (SELECT * FROM ml.customer_features))
ORDER BY predicted
LIMIT 10;

