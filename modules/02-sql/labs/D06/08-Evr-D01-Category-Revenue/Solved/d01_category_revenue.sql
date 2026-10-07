-- D06 · 4.2 Everyone Do: D01's answer, in SQL
-- It is September 2026, the setting of D01:
-- "Which product category produced the most completed-order revenue last month?"
-- Last month is August 2026. On D01 you worked it out by hand: Accessories, 166.00.

-- Audit step 1: order_items alone. One row is one product on one order. (12 rows, 487.00)
-- @check 1
SELECT COUNT(*) AS row_count,
       SUM(qty * price) AS line_value
FROM D03.order_items;

-- Audit step 2: add orders, to know each line's status. Each line finds one order,
-- so the rows and the total do not change. (12 rows, 487.00)
-- @check 2
SELECT COUNT(*) AS row_count,
       SUM(i.qty * i.price) AS line_value
FROM D03.order_items AS i
INNER JOIN D03.orders AS o
  ON i.order_id = o.order_id;

-- Audit step 3: add products, to know each line's category. Still 12 rows, still 487.00.
-- @check 3
SELECT COUNT(*) AS row_count,
       SUM(i.qty * i.price) AS line_value
FROM D03.order_items AS i
INNER JOIN D03.orders AS o
  ON i.order_id = o.order_id
INNER JOIN D03.products AS p
  ON i.product_id = p.product_id;

-- The answer: completed orders placed last month, grouped by category. (3 rows)
-- "Last month" written as dates gives the same answer whenever the query runs.
-- @check 4
SELECT p.category,
       SUM(i.qty * i.price) AS revenue
FROM D03.order_items AS i
INNER JOIN D03.orders AS o
  ON i.order_id = o.order_id
INNER JOIN D03.products AS p
  ON i.product_id = p.product_id
WHERE o.status = 'completed'
  AND o.order_date BETWEEN '2026-08-01' AND '2026-08-31'
GROUP BY p.category
ORDER BY revenue DESC;

-- Without the status filter, the cancelled order changes the winner: Shoes, 195.00.
-- The orders join and the date filter stay; only the status test is gone.
-- @check 5
SELECT p.category,
       SUM(i.qty * i.price) AS revenue
FROM D03.order_items AS i
INNER JOIN D03.orders AS o
  ON i.order_id = o.order_id
INNER JOIN D03.products AS p
  ON i.product_id = p.product_id
WHERE o.order_date BETWEEN '2026-08-01' AND '2026-08-31'
GROUP BY p.category
ORDER BY revenue DESC;
