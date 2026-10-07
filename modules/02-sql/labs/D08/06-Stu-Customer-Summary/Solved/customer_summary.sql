-- D08 · 3.3 Student Do: One row per customer

-- 1. Step 1 alone: completed orders per customer, with the first and last completed order. (452 rows)
-- first_order and last_order count completed orders only: the WHERE keeps no others.
-- @check 1
WITH completed AS (
  SELECT customer_id,
         COUNT(*) AS completed_orders,
         SUM(order_total) AS revenue,
         MIN(order_date) AS first_order,
         MAX(order_date) AS last_order
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
)
SELECT *
FROM completed;

-- 2. Every customer, with their completed orders; 0 for those with none. (500 rows; C-1380 Leen Najjar first, 82 orders, 35,338.50)
-- @check 2
WITH completed AS (
  SELECT customer_id,
         COUNT(*) AS completed_orders,
         SUM(order_total) AS revenue,
         MIN(order_date) AS first_order,
         MAX(order_date) AS last_order
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
)
SELECT c.customer_id,
       c.customer_name,
       COALESCE(LOWER(TRIM(c.segment)), 'unknown') AS segment_clean,
       COALESCE(x.completed_orders, 0) AS completed_orders,
       ROUND(COALESCE(x.revenue, 0), 2) AS revenue,
       x.first_order,
       x.last_order
FROM nakheel.customers AS c
LEFT JOIN completed AS x
  ON c.customer_id = x.customer_id
ORDER BY revenue DESC;

-- 3. The audit: rows, orders and revenue in the summary. (1 row: 500 customers; 2,770 orders; 315,085.50; 49 with none)
-- 315,085.50 is 938.00 short of 316,023.50: order 101664's customer is not in customers, so it has no row here.
-- @check 3
WITH completed AS (
  SELECT customer_id,
         COUNT(*) AS completed_orders,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
),
summary AS (
  SELECT c.customer_id,
         COALESCE(x.completed_orders, 0) AS completed_orders,
         COALESCE(x.revenue, 0) AS revenue
  FROM nakheel.customers AS c
  LEFT JOIN completed AS x
    ON c.customer_id = x.customer_id
)
SELECT COUNT(*) AS customers,
       SUM(completed_orders) AS completed_orders,
       ROUND(SUM(revenue), 2) AS revenue,
       COUNTIF(completed_orders = 0) AS customers_with_none
FROM summary;

-- Bonus (not checked). Which customers have placed orders, but none of them completed?
-- They are the other 10 of the 49 with none; the 39 who never ordered are the rest. (10 rows)
-- @check Bonus
WITH completed AS (
  SELECT customer_id,
         COUNT(*) AS completed_orders
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
)
SELECT c.customer_id,
       c.customer_name
FROM nakheel.customers AS c
LEFT JOIN completed AS x
  ON c.customer_id = x.customer_id
WHERE x.customer_id IS NULL
  AND c.customer_id IN (SELECT customer_id FROM nakheel.orders)
ORDER BY c.customer_id;
