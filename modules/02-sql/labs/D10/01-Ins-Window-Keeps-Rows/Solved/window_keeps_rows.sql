-- D10 · 2.1 Instructor Do: A window keeps the rows

-- 1. GROUP BY collapses: the average month. (1 row: 13,167.65)
-- @check 1
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
)
SELECT ROUND(AVG(revenue), 2) AS avg_month
FROM monthly;

-- 2. OVER () keeps the rows. (24 rows; 13,167.65 on every row)
-- @check 2
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
)
SELECT month,
       revenue,
       ROUND(AVG(revenue) OVER (), 2) AS avg_month
FROM monthly
ORDER BY month;

-- 3. The months above the average: the window in a CTE, then WHERE. (8 rows; April 2026, 20,237.00)
-- @check 3
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
),
with_average AS (
  SELECT month,
         revenue,
         AVG(revenue) OVER () AS avg_month
  FROM monthly
)
SELECT month,
       ROUND(revenue, 2) AS revenue
FROM with_average
WHERE revenue > avg_month
ORDER BY month;

-- 4. The dead end: a window function is not allowed in WHERE.
-- @skip
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
)
SELECT month, revenue
FROM monthly
WHERE revenue > AVG(revenue) OVER ();
