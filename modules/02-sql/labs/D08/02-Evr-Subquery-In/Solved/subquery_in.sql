-- D08 · 2.2 Everyone Do: A list from another table, with IN
-- "How many completed orders came from wholesale customers, and what were they worth?"

-- 1. The inner query alone: the wholesale customers. (65 rows)
-- @check 1
SELECT customer_id
FROM nakheel.customers
WHERE LOWER(TRIM(segment)) = 'wholesale';

-- 2. Use that list in the WHERE of the outer query. (1 row: 377 orders, 154,204.00)
-- @check 2
SELECT COUNT(*) AS completed_orders,
       ROUND(SUM(order_total), 2) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
  AND customer_id IN (SELECT customer_id
                      FROM nakheel.customers
                      WHERE LOWER(TRIM(segment)) = 'wholesale');

-- 3. The same answer with a join, as on D07. (1 row: 377 orders, 154,204.00)
-- @check 3
SELECT COUNT(*) AS completed_orders,
       ROUND(SUM(o.order_total), 2) AS revenue
FROM nakheel.orders AS o
INNER JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
  AND LOWER(TRIM(c.segment)) = 'wholesale';
