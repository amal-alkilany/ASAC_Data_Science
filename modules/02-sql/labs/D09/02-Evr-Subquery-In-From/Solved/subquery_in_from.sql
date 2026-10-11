-- D09 · 2.2 Everyone Do: Do our customers come back?

-- 1. Step 1 alone: completed orders per customer. (452 rows; C-1270 first, 126)
-- @check 1
SELECT customer_id,
       COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY customer_id
ORDER BY completed_orders DESC;

-- 2. The shortcut that does not work: Aggregations of aggregations are not allowed.
-- @skip
SELECT AVG(COUNT(*)) AS avg_orders
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY customer_id;

-- 3. Step 1 in FROM. (1 row: 6.13, 1, 126)
-- @check 3
SELECT ROUND(AVG(completed_orders), 2) AS avg_orders,
       MIN(completed_orders) AS fewest,
       MAX(completed_orders) AS most
FROM (SELECT customer_id,
             COUNT(*) AS completed_orders
      FROM nakheel.orders
      WHERE status = 'completed'
      GROUP BY customer_id) AS per_customer;

-- 4. Bought once, or came back? (2 rows: came back 323, one order 129)
-- @check 4
SELECT CASE
         WHEN completed_orders = 1 THEN 'one order'
         ELSE 'came back'
       END AS kind,
       COUNT(*) AS customers
FROM (SELECT customer_id,
             COUNT(*) AS completed_orders
      FROM nakheel.orders
      WHERE status = 'completed'
      GROUP BY customer_id) AS per_customer
GROUP BY kind
ORDER BY kind;
