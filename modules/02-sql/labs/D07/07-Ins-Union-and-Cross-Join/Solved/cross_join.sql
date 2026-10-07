-- D07 · 4.2 Instructor Do: CROSS JOIN
-- CROSS JOIN pairs every row of one table with every row of the other. There is no ON.
-- Rows out = rows in A × rows in B.

-- 5 customers × 5 orders = 25 rows. Each row is one pair, whether the keys match or not.
-- @check Cross 1
SELECT c.customer_id, o.order_id, o.customer_id AS order_customer
FROM D03.customers AS c
CROSS JOIN D03.orders AS o
ORDER BY c.customer_id, o.order_id;

-- Keep only the pairs where the keys match: the same 5 rows as the INNER JOIN in D06 2.3.
-- @check Cross 2
SELECT c.customer_id, o.order_id
FROM D03.customers AS c
CROSS JOIN D03.orders AS o
WHERE c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

-- At Nakheel the same pairing makes 500 × 3,000 = 1,500,000 rows. Count them; do not SELECT them.
-- @check Cross 3
SELECT COUNT(*) AS pairs
FROM nakheel.customers AS c
CROSS JOIN nakheel.orders AS o;

-- A use: every customer against every category, so the pairs with no sale still get a row.
-- The brackets make a list of the 3 categories (a subquery: D08). 5 × 3 = 15 rows.
-- @check Cross 4
SELECT c.customer_id, cat.category
FROM D03.customers AS c
CROSS JOIN (SELECT DISTINCT category FROM D03.products) AS cat
ORDER BY c.customer_id, cat.category;

-- Shown, not typed: the same 15 pairs with the completed revenue in each (0 where none).
-- 9 pairs are 0. Four customers never bought Outerwear: C-118, C-204, C-377, C-455.
-- C-118's rain jacket was on cancelled order 1002, so it does not count.
-- @check Cross 5
SELECT c.customer_id,
       cat.category,
       COALESCE(SUM(CASE WHEN p.product_id IS NOT NULL THEN i.qty * i.price END), 0) AS revenue
FROM D03.customers AS c
CROSS JOIN (SELECT DISTINCT category FROM D03.products) AS cat
LEFT JOIN D03.orders AS o
  ON o.customer_id = c.customer_id AND o.status = 'completed'
LEFT JOIN D03.order_items AS i
  ON i.order_id = o.order_id
LEFT JOIN D03.products AS p
  ON p.product_id = i.product_id AND p.category = cat.category
GROUP BY c.customer_id, cat.category
ORDER BY c.customer_id, cat.category;
