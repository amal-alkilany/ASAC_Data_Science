-- D10 · 2.3 Student Do: Window practice: compare a row with its group

-- 1. Each completed order next to its channel's average. (2,771 rows; 100001 store 22.50, 116.47)
-- @check 1
SELECT order_id,
       channel,
       order_total,
       ROUND(AVG(order_total) OVER (PARTITION BY channel), 2) AS channel_avg
FROM nakheel.orders
WHERE status = 'completed'
ORDER BY order_id;

-- 2. Customers above their own segment's average. (2 rows: retail 98, wholesale 11)
-- @check 2
WITH customer_revenue AS (
  SELECT o.customer_id,
         LOWER(TRIM(c.segment)) AS segment_clean,
         SUM(o.order_total) AS revenue
  FROM nakheel.orders AS o
  INNER JOIN nakheel.customers AS c
    ON o.customer_id = c.customer_id
  WHERE o.status = 'completed'
  GROUP BY o.customer_id, segment_clean
),
with_segment_average AS (
  SELECT customer_id,
         segment_clean,
         revenue,
         AVG(revenue) OVER (PARTITION BY segment_clean) AS segment_avg
  FROM customer_revenue
)
SELECT segment_clean,
       COUNT(*) AS customers_above_average
FROM with_segment_average
WHERE revenue > segment_avg
GROUP BY segment_clean
ORDER BY segment_clean;

-- 3. Each month's share of its year. (24 rows; December 2024 first, 28.2)
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
       SUM(revenue) OVER (PARTITION BY EXTRACT(YEAR FROM month)) AS year_revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (PARTITION BY EXTRACT(YEAR FROM month)), 1) AS share_pct
FROM monthly
ORDER BY share_pct DESC;
-- The data runs from September 2024 to August 2026: 2024 has only four months, so each is a big share.

-- Bonus: the biggest share among the twelve months of 2025. (September 2025, 11.8)
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
),
shares AS (
  SELECT month,
         ROUND(100 * revenue / SUM(revenue) OVER (PARTITION BY EXTRACT(YEAR FROM month)), 1) AS share_pct
  FROM monthly
)
SELECT month, share_pct
FROM shares
WHERE EXTRACT(YEAR FROM month) = 2025
ORDER BY share_pct DESC
LIMIT 1;
