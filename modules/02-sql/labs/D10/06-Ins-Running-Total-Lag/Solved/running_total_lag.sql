-- D10 · 4.1 Instructor Do: Running totals and the month before

-- 2. A running total. (24 rows; the last is 316,023.50)
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
       SUM(revenue) OVER (ORDER BY month) AS running_total
FROM monthly
ORDER BY month;

-- 3. The month before, with LAG. (24 rows; April 2026 +5,792.50; May 2026 -7,473.00)
-- @check 3
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
)
SELECT month,
       revenue,
       SUM(revenue) OVER (ORDER BY month) AS running_total,
       LAG(revenue) OVER (ORDER BY month) AS previous_month,
       revenue - LAG(revenue) OVER (ORDER BY month) AS change
FROM monthly
ORDER BY month;

-- 4. Year to date: the running total restarts each year. (24 rows; December 2025 147,589.00)
-- @check 4
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
)
SELECT month,
       revenue,
       SUM(revenue) OVER (PARTITION BY EXTRACT(YEAR FROM month) ORDER BY month) AS year_to_date
FROM monthly
ORDER BY month;
