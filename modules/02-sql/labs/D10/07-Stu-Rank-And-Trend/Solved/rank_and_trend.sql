-- D10 · 4.3 Student Do: Window practice: rank and trend

-- 1. The three biggest completed orders in each channel. (6 rows)
-- @check 1
SELECT channel,
       order_id,
       order_total,
       ROW_NUMBER() OVER (PARTITION BY channel ORDER BY order_total DESC) AS place
FROM nakheel.orders
WHERE status = 'completed'
QUALIFY place <= 3
ORDER BY channel, place;

-- 2. Each channel's monthly revenue and its change, biggest jump first. (48 rows; store, September 2025, +5,399.00)
-- @check 2
WITH channel_month AS (
  SELECT channel,
         DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY channel, month
)
SELECT channel,
       month,
       revenue,
       revenue - LAG(revenue) OVER (PARTITION BY channel ORDER BY month) AS change
FROM channel_month
ORDER BY change DESC;

-- 3. The three best months. (3 rows; April 2026, September 2025, June 2026)
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
       RANK() OVER (ORDER BY revenue DESC) AS month_rank
FROM monthly
QUALIFY month_rank <= 3
ORDER BY month_rank;

-- Bonus: a running total for each channel. (48 rows; last online 110,685.50, last store 205,338.00)
WITH channel_month AS (
  SELECT channel,
         DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY channel, month
)
SELECT channel,
       month,
       revenue,
       revenue - LAG(revenue) OVER (PARTITION BY channel ORDER BY month) AS change,
       SUM(revenue) OVER (PARTITION BY channel ORDER BY month) AS running_total
FROM channel_month
ORDER BY channel, month;
