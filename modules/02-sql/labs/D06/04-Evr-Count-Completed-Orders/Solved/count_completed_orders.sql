-- D06 · 3.1 Everyone Do: "How many completed orders?"

-- 1. On orders. One row is one order. (4)
-- @check 1
SELECT COUNT(*) AS completed_orders
FROM D03.orders
WHERE status = 'completed';

-- 2. After joining order_items. One row is now one product on one order. (10)
--    The join is correct. The grain changed, so COUNT(*) now counts order lines.
-- @check 2
SELECT COUNT(*) AS rows_after_join
FROM D03.orders AS o
INNER JOIN D03.order_items AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed';

-- 3. Count what the question asks for: different orders. (4)
-- @check 3
SELECT COUNT(DISTINCT o.order_id) AS completed_orders
FROM D03.orders AS o
INNER JOIN D03.order_items AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed';

-- For question 1 you do not need the join: query 1 is the answer.
-- Join only when the question needs a column from the other table.

-- 4. "How many completed orders included at least one item priced 20 or more?"
--    This one needs the join: status is in orders, price is in order_items.
--    COUNT(*) gives 3, because order 1004 has two items priced 20 or more
--    (P-05 at 42.00 and P-23 at 26.00) and appears twice.
-- @check 4a
SELECT COUNT(*) AS rows_after_join
FROM D03.orders AS o
INNER JOIN D03.order_items AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed'
  AND i.price >= 20;

--    Count different orders instead: orders 1003 and 1004. (2)
-- @check 4b
SELECT COUNT(DISTINCT o.order_id) AS completed_orders
FROM D03.orders AS o
INNER JOIN D03.order_items AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed'
  AND i.price >= 20;
