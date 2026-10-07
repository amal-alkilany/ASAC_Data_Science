-- D08 · 3.1 Instructor Do: From nested to named
-- "What does a typical customer who has bought from us spend, in each segment?" Two grains: first one row per customer, then one row per segment.

-- 1. Step 1 alone: completed revenue per customer. (452 rows; C-1380: 82 orders, 35,338.50)
-- @check 1
SELECT customer_id,
       COUNT(*) AS completed_orders,
       SUM(order_total) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY customer_id;

-- 2. Nested: step 1 inside the FROM of step 2. It runs, and it is hard to read from the top. (3 rows)
-- @check 2
SELECT COALESCE(LOWER(TRIM(c.segment)), 'unknown') AS segment_clean,
       COUNT(*) AS customers,
       ROUND(AVG(cr.revenue), 2) AS avg_revenue_per_customer
FROM (SELECT customer_id, COUNT(*) AS completed_orders, SUM(order_total) AS revenue
      FROM nakheel.orders
      WHERE status = 'completed'
      GROUP BY customer_id) AS cr
LEFT JOIN nakheel.customers AS c
  ON cr.customer_id = c.customer_id
GROUP BY segment_clean
ORDER BY avg_revenue_per_customer DESC;

-- 3. Named: the same query with a CTE. WITH gives step 1 a name; step 2 reads it like a table.
-- (3 rows: wholesale 58 customers, 2,658.69; unknown 1, 938.00; retail 393, 409.37)
-- @check 3
WITH customer_revenue AS (
  SELECT customer_id,
         COUNT(*) AS completed_orders,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
)
SELECT COALESCE(LOWER(TRIM(c.segment)), 'unknown') AS segment_clean,
       COUNT(*) AS customers,
       ROUND(AVG(cr.revenue), 2) AS avg_revenue_per_customer
FROM customer_revenue AS cr
LEFT JOIN nakheel.customers AS c
  ON cr.customer_id = c.customer_id
GROUP BY segment_clean
ORDER BY avg_revenue_per_customer DESC;
