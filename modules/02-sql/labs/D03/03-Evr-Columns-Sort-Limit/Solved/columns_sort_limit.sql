-- D03 · 4.2 Everyone Do: choose columns, rename, sort, limit

-- 1. Name the columns you want, in the order you want them. (5 rows)
-- @check 1
SELECT order_id, order_date, status
FROM D03.orders;

-- 2. AS renames the column in the result. The table is not changed. (5 rows)
-- @check 2
SELECT order_id AS order_number, order_date, status
FROM D03.orders;

-- 3. ORDER BY sorts the result. DESC means largest first. (12 rows)
-- @check 3
SELECT item_id, order_id, product_id, qty, price
FROM D03.order_items
ORDER BY price DESC;

-- 4. LIMIT keeps the first rows of the sorted result. The second sort column
--    decides ties, so everyone gets the three rows in the same order. (3 rows: 9010, 9003, 9009)
-- @check 4
SELECT item_id, order_id, product_id, qty
FROM D03.order_items
ORDER BY qty DESC, item_id
LIMIT 3;
