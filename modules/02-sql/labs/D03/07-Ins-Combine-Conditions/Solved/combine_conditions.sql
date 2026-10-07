-- D03 · 5.3 Instructor Do: combine conditions (AND, OR, brackets, IN, BETWEEN, LIKE, DISTINCT)

-- Query 1
-- AND: both must be true. (2 rows: 1004, 1005)
-- @check 1
SELECT order_id, order_date, status
FROM D03.orders
WHERE status = 'completed'
  AND order_date >= '2026-08-16';

-- Query 2
-- The OR trap. Question: completed orders from C-118 or C-204.
-- AND is worked out before OR, so this reads "C-118 (any status), or C-204 and completed".
-- It returns 4 rows, including the cancelled order 1002.
-- @check 2
SELECT order_id, customer_id, status
FROM D03.orders
WHERE customer_id = 'C-118' OR customer_id = 'C-204' AND status = 'completed';

-- Query 3
-- Brackets say what you mean. (3 rows: 1001, 1003, 1005)
-- @check 3
SELECT order_id, customer_id, status
FROM D03.orders
WHERE (customer_id = 'C-118' OR customer_id = 'C-204')
  AND status = 'completed';

-- Query 4
-- IN is a shorter way to write several ORs on one column. (3 rows)
-- @check 4
SELECT order_id, customer_id, status
FROM D03.orders
WHERE customer_id IN ('C-118', 'C-204')
  AND status = 'completed';

-- Query 5
-- IN also catches the three spellings of retail from 4.3. (3 rows)
-- @check 5
SELECT customer_id, segment
FROM D03.customers
WHERE segment IN ('Retail', 'retail', 'RETAIL ');

-- Query 6
-- BETWEEN includes both ends. (3 rows: 1001, 1002, 1003)
-- @check 6
SELECT order_id, order_date
FROM D03.orders
WHERE order_date BETWEEN '2026-08-01' AND '2026-08-11';

-- Query 7
-- LIKE matches a pattern: % means "any characters". (2 rows: C-204, C-401)
-- @check 7
SELECT customer_id, customer_name
FROM D03.customers
WHERE customer_name LIKE 'Omar%';

-- Query 8
-- LIKE is case-sensitive: 'Trail shoe' has a small s, so this finds nothing. (0 rows)
-- @check 8
SELECT product_id, product_name
FROM D03.products
WHERE product_name LIKE '%Shoe%';

-- Query 9
-- DISTINCT removes repeated rows from the result. 5 orders, 3 different customers. (3 rows)
-- @check 9
SELECT DISTINCT customer_id
FROM D03.orders;
