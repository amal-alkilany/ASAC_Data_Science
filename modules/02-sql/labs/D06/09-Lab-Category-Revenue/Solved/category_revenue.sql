-- ============================================================
-- D06 · 5.2 Lab: Revenue by category, with a join audit · SOLVED
-- Tables: nakheel.order_items, nakheel.products, nakheel.orders
-- (The Pagila films part moved to D07 5.1: labs/D07/08-Evr-Films-Per-Category.)
-- ============================================================

-- ============================================================
-- C1 · Two tables: revenue by category (all orders), order_items + products
-- Five Checks: order_items: one product on one order. products: one product.
-- Key: product_id. Unique in products? (step 1 below.) Rows expected after the join: 7,516.
-- ============================================================

-- Step 1. Is product_id unique in products? (60 and 60)
-- @check 1
SELECT COUNT(*) AS product_rows,
       COUNT(DISTINCT product_id) AS different_ids
FROM nakheel.products;

-- Step 2. Audit, before: order_items alone.
-- @check 2
SELECT COUNT(*) AS row_count,
       SUM(qty * price) AS line_value
FROM nakheel.order_items;

-- Step 3. Audit, after joining products: same rows, same total.
-- @check 3
SELECT COUNT(*) AS row_count,
       SUM(i.qty * i.price) AS line_value
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id;

-- Step 4. Revenue by category, all orders.
-- One row is: one category
-- @check 4
SELECT p.category,
       SUM(i.qty * i.price) AS revenue
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- ============================================================
-- C2 · Three tables: completed orders by category
-- ============================================================

-- Step 5. Audit after joining orders as well: still 7,516 rows and the same total.
-- @check 5
SELECT COUNT(*) AS row_count,
       SUM(i.qty * i.price) AS line_value
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id
INNER JOIN nakheel.orders AS o
  ON i.order_id = o.order_id;

-- Step 6. Audit after keeping completed orders only.
-- @check 6
SELECT COUNT(*) AS row_count,
       SUM(i.qty * i.price) AS line_value
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id
INNER JOIN nakheel.orders AS o
  ON i.order_id = o.order_id
WHERE o.status = 'completed';

-- Step 7. Cross-check: completed revenue from the orders table alone must be the same number.
-- @check 7
SELECT SUM(order_total) AS completed_revenue
FROM nakheel.orders
WHERE status = 'completed';

-- Step 8. The answer the D04 managers asked for: completed revenue by category, whole period.
-- One row is: one category
-- @check 8
SELECT p.category,
       SUM(i.qty * i.price) AS revenue
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id
INNER JOIN nakheel.orders AS o
  ON i.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- ============================================================
-- C3 · Completed revenue by category and month
-- ============================================================

-- Step 9. Completed revenue by category and month.
-- One row is: one category in one month
-- @check 9
SELECT p.category,
       DATE_TRUNC(o.order_date, MONTH) AS month,
       SUM(i.qty * i.price) AS revenue
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id
INNER JOIN nakheel.orders AS o
  ON i.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY p.category, month
ORDER BY month, revenue DESC;

-- ============================================================
-- Stretch card (not checked): thelook_ecommerce, key check first
-- ============================================================
-- @skip public dataset
SELECT COUNT(*) AS product_rows, COUNT(DISTINCT id) AS different_ids
FROM `bigquery-public-data.thelook_ecommerce.products`;

-- @skip public dataset
SELECT p.category, ROUND(SUM(oi.sale_price), 2) AS revenue
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
INNER JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id
WHERE oi.status = 'Complete'
GROUP BY p.category
ORDER BY revenue DESC
LIMIT 10;

-- ============================================================
-- More practice (not checked, not submitted)
-- (The never-ordered, segment and Pagila rating questions moved to the D07 lab's more practice.)
-- ============================================================

-- X1 Units sold per category, completed orders.
-- @check X1
SELECT p.category, SUM(i.qty) AS units
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id
INNER JOIN nakheel.orders AS o
  ON i.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY units DESC;

-- X2 Omar Nasser from Irbid has two customer IDs. What has he spent on completed orders
--    under each ID? Add the two rows to get his total: 3 + 18 = 21 orders, 143.00 + 6,033.00 = 6,176.00.
-- @check X2
SELECT c.customer_id,
       COUNT(*) AS completed_orders,
       SUM(o.order_total) AS spent
FROM nakheel.customers AS c
INNER JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id
WHERE c.customer_name = 'Omar Nasser'
  AND o.status = 'completed'
GROUP BY c.customer_id;

-- X3 Transfer (thelook_ecommerce, no fixed answer): read the bytes estimate, then run.
-- @skip public dataset
SELECT u.country, COUNT(DISTINCT o.order_id) AS orders
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
INNER JOIN `bigquery-public-data.thelook_ecommerce.users` AS u
  ON o.user_id = u.id
GROUP BY u.country
ORDER BY orders DESC
LIMIT 10;
