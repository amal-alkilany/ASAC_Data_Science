-- D07 · 6.2 Lab: A joined report with an audit · SOLVED

-- C1 · step 1. Audit before: completed orders on orders alone. (1 row: 2,771; 316,023.50)
-- @check 1
SELECT COUNT(*) AS completed_orders,
       SUM(order_total) AS revenue
FROM nakheel.orders
WHERE status = 'completed';

-- C1 · step 2. Audit after LEFT JOIN customers: nothing lost, nothing copied. (1 row: 2,771; 2,771; 316,023.50)
-- @check 2
SELECT COUNT(*) AS row_count,
       COUNT(DISTINCT o.order_id) AS different_orders,
       SUM(o.order_total) AS revenue
FROM nakheel.orders AS o
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed';

-- C1 · step 3. Completed revenue by cleaned segment and channel. (5 rows: wholesale, store first, 103,069.00)
-- @check 3
SELECT COALESCE(LOWER(TRIM(c.segment)), 'unknown') AS segment_clean,
       o.channel,
       COUNT(*) AS completed_orders,
       SUM(o.order_total) AS revenue
FROM nakheel.orders AS o
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY segment_clean, o.channel
ORDER BY revenue DESC;

-- C2 · step 4. Segment by size band. (7 rows: wholesale, large first, 264 orders, 141,847.50)
-- @check 4
SELECT COALESCE(LOWER(TRIM(c.segment)), 'unknown') AS segment_clean,
       CASE
         WHEN o.order_total >= 200 THEN 'large'
         WHEN o.order_total >= 50 THEN 'medium'
         ELSE 'small'
       END AS size_band,
       COUNT(*) AS completed_orders,
       SUM(o.order_total) AS revenue
FROM nakheel.orders AS o
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY segment_clean, size_band
ORDER BY revenue DESC;

-- C2 · step 5. Only the groups worth more than 20,000. (3 rows: wholesale large, retail medium, retail small)
-- @check 5
SELECT COALESCE(LOWER(TRIM(c.segment)), 'unknown') AS segment_clean,
       CASE
         WHEN o.order_total >= 200 THEN 'large'
         WHEN o.order_total >= 50 THEN 'medium'
         ELSE 'small'
       END AS size_band,
       COUNT(*) AS completed_orders,
       SUM(o.order_total) AS revenue
FROM nakheel.orders AS o
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY segment_clean, size_band
HAVING SUM(o.order_total) > 20000
ORDER BY revenue DESC;

-- C3 · step 6. One list of everything with no match: customers who never ordered and products never sold,
-- stacked with UNION ALL. Both halves return the same three columns. (43 rows: 39 customers + 4 products)
-- @check 6
SELECT 'customer' AS gap_type,
       c.customer_id AS id,
       c.customer_name AS name
FROM nakheel.customers AS c
LEFT JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'product' AS gap_type,
       p.product_id AS id,
       p.product_name AS name
FROM nakheel.products AS p
LEFT JOIN nakheel.order_items AS i
  ON p.product_id = i.product_id
WHERE i.item_id IS NULL
ORDER BY gap_type, id;

-- ============================================================
-- Stretch card (not checked): thelook_ecommerce, key check first
-- ============================================================
-- @skip public dataset
SELECT COUNT(*) AS user_rows, COUNT(DISTINCT id) AS different_ids
FROM `bigquery-public-data.thelook_ecommerce.users`;

-- @skip public dataset
SELECT u.traffic_source, COUNT(*) AS users_without_orders
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o
  ON u.id = o.user_id
WHERE o.order_id IS NULL
GROUP BY u.traffic_source;

-- ============================================================
-- More practice (not checked, not submitted)
-- (Moved from the old D06 lab, where they were X1, X2 and X5.)
-- ============================================================

-- X1 Customers who never ordered, per city as typed.
-- @check X1
SELECT c.city, COUNT(*) AS customers_without_orders
FROM nakheel.customers AS c
LEFT JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
GROUP BY c.city;

-- X2 Completed revenue by customer segment, cleaned. Audit: the orphan order is lost by INNER JOIN.
-- @check X2
SELECT LOWER(TRIM(c.segment)) AS segment_clean,
       COUNT(*) AS completed_orders,
       SUM(o.order_total) AS revenue
FROM nakheel.orders AS o
INNER JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY segment_clean;

-- X2 audit: the completed order that has no customer, and its value.
-- @check X2a
SELECT o.order_id, o.order_total
FROM nakheel.orders AS o
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
  AND c.customer_id IS NULL;

-- X3 Pagila: films per rating, and the average running time.
-- @check X3
SELECT rating, COUNT(*) AS films, ROUND(AVG(length), 1) AS average_minutes
FROM pagila.film
GROUP BY rating;
