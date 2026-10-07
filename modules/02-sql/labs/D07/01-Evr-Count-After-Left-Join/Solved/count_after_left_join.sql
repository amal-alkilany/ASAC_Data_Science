-- D07 · 2.1 Everyone Do: COUNT(*) against COUNT(column) after a LEFT JOIN

-- 1. Orders per customer, every customer kept. Sorted so customers with no orders come first.
--    For them, COUNT(*) says 1 (the row the LEFT JOIN kept) and COUNT(o.order_id) says 0.
-- @check 1
SELECT c.customer_id,
       COUNT(*) AS rows_counted,
       COUNT(o.order_id) AS orders
FROM nakheel.customers AS c
LEFT JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id
GROUP BY c.customer_id
ORDER BY orders, c.customer_id;

-- 3. The whole join, counted three ways. (Step 2 of the README only changes the sort of query 1.)
-- @check 3
SELECT COUNT(*) AS rows_after_left_join,
       COUNT(o.order_id) AS orders_found,
       COUNT(DISTINCT c.customer_id) AS customers
FROM nakheel.customers AS c
LEFT JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id;
