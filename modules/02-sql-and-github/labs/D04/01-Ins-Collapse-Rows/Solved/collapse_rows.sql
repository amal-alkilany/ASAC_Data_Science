-- D04 · 2.1–2.2 Instructor Do: a new column on every row, then rows collapse into groups
-- Table: D03.order_items. One row is one product on one order.

-- 2.1 Line revenue: a calculation makes a new column, one value per row. (12 rows)
SELECT item_id, order_id, product_id, qty, price,
       qty * price AS line_revenue
FROM D03.order_items
ORDER BY item_id;

-- 2.2 Group by order: 12 rows collapse into 5. One row of the result is one order.
SELECT order_id,
       COUNT(*) AS lines,
       SUM(qty * price) AS order_revenue
FROM D03.order_items
GROUP BY order_id
ORDER BY order_id;

-- Group by product: the same 12 rows collapse into 5 different groups.
-- One row of the result is one product.
SELECT product_id,
       SUM(qty) AS units,
       SUM(qty * price) AS product_revenue
FROM D03.order_items
GROUP BY product_id
ORDER BY product_revenue DESC;

-- The error everyone will meet. product_id is neither grouped nor summarised,
-- so BigQuery cannot choose one product_id for each order.
-- Error: SELECT list expression references column product_id which is neither grouped nor aggregated
-- @skip fails on purpose
SELECT order_id, product_id, SUM(qty * price) AS order_revenue
FROM D03.order_items
GROUP BY order_id;
