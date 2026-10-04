-- D06 · 2.3 Everyone Do: INNER JOIN and LEFT JOIN on D03

-- 1. Each order with its customer's name and city. One row is one order. (5 rows)
-- @check 1
SELECT o.order_id, o.status, c.customer_name, c.city
FROM D03.orders AS o
INNER JOIN D03.customers AS c
  ON o.customer_id = c.customer_id
ORDER BY o.order_id;

-- 2. Every customer, with their orders if they have any. (7 rows)
--    C-377 and C-455 have no orders: their order columns are NULL.
-- @check 2
SELECT c.customer_id, c.customer_name, o.order_id, o.status
FROM D03.customers AS c
LEFT JOIN D03.orders AS o
  ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

-- 3. The same two tables with INNER JOIN: the two customers without orders disappear. (5 rows)
-- @check 3
SELECT c.customer_id, c.customer_name, o.order_id, o.status
FROM D03.customers AS c
INNER JOIN D03.orders AS o
  ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;
