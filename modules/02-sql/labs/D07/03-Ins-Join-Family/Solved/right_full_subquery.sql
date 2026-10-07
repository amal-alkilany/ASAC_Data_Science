-- D07 · 2.4 Instructor Do: The join family: RIGHT, FULL and the no-match joins (and a preview of D08)
-- UNION and CROSS JOIN are in 07-Ins-Union-and-Cross-Join (D07 4.1 and 4.2).

-- RIGHT JOIN keeps every row of the table on the right. It is a LEFT JOIN written backwards:
-- these two queries return the same 3,038 rows.
-- @check 1
SELECT COUNT(*) AS rows_right_join
FROM nakheel.orders AS o
RIGHT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id;

-- @check 2
SELECT COUNT(*) AS rows_left_join
FROM nakheel.customers AS c
LEFT JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id;

-- With customers written first, RIGHT JOIN keeps every order instead:
-- 2,999 matched orders + the orphan order 101664 = 3,000 rows.
-- @check 3
SELECT COUNT(*) AS rows_right_join_orders_kept
FROM nakheel.customers AS c
RIGHT JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id;

-- FULL OUTER JOIN keeps unmatched rows from both sides: the customers with no orders
-- AND the orphan order with no customer. (3,039 rows)
-- @check 4
SELECT COUNT(*) AS rows_full_join,
       COUNTIF(o.order_id IS NULL) AS customers_without_orders,
       COUNTIF(c.customer_id IS NULL) AS orders_without_customer
FROM nakheel.customers AS c
FULL OUTER JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id;

-- The no-match joins: keep only the rows that found nothing on the other side.
-- Left side: customers with no order (39). Power Query calls this a left anti join.
-- @check 5
SELECT COUNT(*) AS customers_without_orders
FROM nakheel.customers AS c
LEFT JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Right side: orders whose customer is missing (1: order 101664, customer C-0999). A right anti join.
-- @check 6
SELECT o.order_id, o.customer_id
FROM nakheel.customers AS c
RIGHT JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- Preview of D08: completed revenue and units by channel. Summarise order_items to one row per order FIRST, then join.
-- Now both tables have one row per order, so order_total is not copied and nothing inflates.
-- @check 7
SELECT o.channel,
       ROUND(SUM(o.order_total), 2) AS revenue,
       SUM(i.units) AS units
FROM nakheel.orders AS o
INNER JOIN (
  SELECT order_id, SUM(qty) AS units
  FROM nakheel.order_items
  GROUP BY order_id
) AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed'
GROUP BY o.channel
ORDER BY o.channel;
