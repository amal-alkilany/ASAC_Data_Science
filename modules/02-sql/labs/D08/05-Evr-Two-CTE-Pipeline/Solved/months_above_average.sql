-- D08 · 3.2 Everyone Do: A two-step pipeline
-- "Which months were better than our average month?"

-- 1. Step 1 alone: completed revenue per month. (24 rows; together 316,023.50)
-- @check 1
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
)
SELECT *
FROM monthly
ORDER BY month;

-- 2. Steps 1 and 2: the average month. (1 row: 13,167.65)
-- @check 2
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
),
average_month AS (
  SELECT AVG(revenue) AS avg_revenue
  FROM monthly
)
SELECT ROUND(avg_revenue, 2) AS avg_revenue
FROM average_month;

-- 3. The answer: months above the average, using the one-number step as a subquery. (8 rows; April 2026 the best, 20,237.00)
-- @check 3
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
),
average_month AS (
  SELECT AVG(revenue) AS avg_revenue
  FROM monthly
)
SELECT month,
       ROUND(revenue, 2) AS revenue
FROM monthly
WHERE revenue > (SELECT avg_revenue FROM average_month)
ORDER BY month;
