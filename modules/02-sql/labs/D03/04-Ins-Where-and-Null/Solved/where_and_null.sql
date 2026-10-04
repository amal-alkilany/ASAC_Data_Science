-- D03 · 4.3 Instructor Do: WHERE, and two planned dead ends

-- Text goes in single quotes. (4 rows)
-- @check 1
SELECT order_id, customer_id, order_date, status
FROM D03.orders
WHERE status = 'completed';

-- Numbers go without quotes. (4 rows)
-- @check 2
SELECT item_id, order_id, product_id, qty, price
FROM D03.order_items
WHERE price > 20;

-- <> means "is not". (4 rows)
-- @check 3
SELECT order_id, status
FROM D03.orders
WHERE status <> 'cancelled';

-- Dead end 1: BigQuery refuses to run this. Error: Operands of = cannot be literal NULL
-- Nothing is ever "equal to" NULL, so the filter could never keep a row.
-- (PostgreSQL, SQL Server and MySQL run it and return 0 rows with no warning.)
-- @skip fails on purpose
SELECT customer_id, customer_name, city
FROM D03.customers
WHERE city = NULL;

-- The fix: IS NULL. (1 row: C-455, Sami Odeh)
-- @check 5
SELECT customer_id, customer_name, city
FROM D03.customers
WHERE city IS NULL;

-- Dead end 2: text comparison is exact. Three customers are retail; this finds one. (1 row: C-204)
-- @check 6
SELECT customer_id, customer_name, segment
FROM D03.customers
WHERE segment = 'retail';

-- Look at every spelling before you filter on text. (5 rows, in this order: 'RETAIL ', Retail, Wholesale,
-- Wholesale, retail. Capital letters sort before small ones.)
-- @check 7
SELECT customer_id, segment
FROM D03.customers
ORDER BY segment;
