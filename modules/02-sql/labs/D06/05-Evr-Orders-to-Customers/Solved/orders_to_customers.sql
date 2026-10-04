-- D06 · 3.2 Everyone Do: Join Nakheel orders to customers

-- 1. Before: one row is one order. (3,000)
-- @check 1
SELECT COUNT(*) AS order_rows
FROM nakheel.orders;

-- 2. INNER JOIN: every order that finds its customer. (2,999: one order is missing)
-- @check 2
SELECT COUNT(*) AS rows_after_inner_join
FROM nakheel.orders AS o
INNER JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id;

-- 3. LEFT JOIN from orders: every order, found or not. (3,000)
-- @check 3
SELECT COUNT(*) AS rows_after_left_join
FROM nakheel.orders AS o
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id;

-- 4. The order the INNER JOIN dropped: its customer_id is not in customers. (1 row)
-- @check 4
SELECT o.order_id, o.customer_id, o.order_date, o.status, o.order_total
FROM nakheel.orders AS o
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
