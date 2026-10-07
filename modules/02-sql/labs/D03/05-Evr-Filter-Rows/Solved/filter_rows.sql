-- D03 · 4.4 Everyone Do: filter rows

-- 1. Customers in Irbid. One row is one customer record. (2 rows: C-204, C-401)
-- @check 1
SELECT customer_id, customer_name, city
FROM D03.customers
WHERE city = 'Irbid';

-- 2. The date is written in quotes; BigQuery converts it to a DATE because order_date is a DATE. (2 rows: 1004, 1005)
-- @check 2
SELECT order_id, order_date, status
FROM D03.orders
WHERE order_date >= '2026-08-15';

-- 3. (7 rows; the first is item 9010 with qty 4)
-- @check 3
SELECT item_id, order_id, product_id, qty
FROM D03.order_items
WHERE qty >= 2
ORDER BY qty DESC, item_id;

-- 4. Error: Unrecognized name: order_number.
--    WHERE runs before SELECT, so the new name does not exist yet when WHERE runs.
--    Run order: FROM, WHERE, SELECT, ORDER BY, LIMIT.
-- @skip fails on purpose
SELECT order_id AS order_number, status
FROM D03.orders
WHERE order_number = 1003;

-- The fix: filter on the column's real name. (1 row)
-- @check 4 (fixed)
SELECT order_id AS order_number, status
FROM D03.orders
WHERE order_id = 1003;
