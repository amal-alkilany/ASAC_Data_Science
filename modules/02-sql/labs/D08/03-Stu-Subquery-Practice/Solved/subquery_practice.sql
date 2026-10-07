-- D08 · 2.3 Student Do: Subquery practice

-- 1. "Which products cost more than our average list price?" (22 rows; the average is 20.35)
-- @check 1
SELECT product_id, product_name, category, list_price
FROM nakheel.products
WHERE list_price > (SELECT AVG(list_price) FROM nakheel.products)
ORDER BY list_price DESC;

-- 2. "Which customers have never placed an order?" with NOT IN. (39 rows: the same 39 as D07's LEFT JOIN)
-- @check 2
SELECT customer_id, customer_name
FROM nakheel.customers
WHERE customer_id NOT IN (SELECT customer_id FROM nakheel.orders)
ORDER BY customer_id;

-- 3. "Which products have never been sold?" (4 rows: P-009, P-025, P-046, P-058)
-- @check 3
SELECT product_id, product_name
FROM nakheel.products
WHERE product_id NOT IN (SELECT product_id FROM nakheel.order_items)
ORDER BY product_id;

-- 4. "Who is our biggest customer by completed revenue?" The inner query returns one customer_id. (1 row: C-1380, Leen Najjar)
-- @check 4
SELECT customer_id, customer_name
FROM nakheel.customers
WHERE customer_id = (SELECT customer_id
                     FROM nakheel.orders
                     WHERE status = 'completed'
                     GROUP BY customer_id
                     ORDER BY SUM(order_total) DESC
                     LIMIT 1);

-- Bonus (not checked). The NOT IN trap: a list that contains a NULL makes NOT IN return no rows.
-- Without a NULL in the list: every customer except C-1001. (499 rows)
-- @check Bonus 1
SELECT customer_id
FROM nakheel.customers
WHERE customer_id NOT IN ('C-1001');

-- With a NULL in the list: "not equal to NULL" is never true, so no row passes. (0 rows)
-- LEFT JOIN ... IS NULL, from D07, does not have this problem.
-- @check Bonus 2
SELECT customer_id
FROM nakheel.customers
WHERE customer_id NOT IN ('C-1001', NULL);
