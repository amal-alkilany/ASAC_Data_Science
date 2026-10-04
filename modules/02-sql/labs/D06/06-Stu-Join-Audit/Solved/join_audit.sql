-- D06 · 3.3 Student Do: Audit the join (orders to order_items)

-- Q1 Before the join. One row is one order.
-- @check 1
SELECT COUNT(*) AS row_count,
       COUNT(DISTINCT order_id) AS different_orders,
       ROUND(SUM(order_total), 2) AS sum_of_order_total
FROM nakheel.orders;

-- Q2 After the join. One row is one product on one order.
-- @check 2
SELECT COUNT(*) AS row_count,
       COUNT(DISTINCT o.order_id) AS different_orders,
       ROUND(SUM(o.order_total), 2) AS sum_of_order_total
FROM nakheel.orders AS o
INNER JOIN nakheel.order_items AS i
  ON o.order_id = i.order_id;

-- Q3 The same money, summed at the grain where it lives after the join: the order line.
-- @check 3
SELECT ROUND(SUM(i.qty * i.price), 2) AS sum_of_line_values
FROM nakheel.orders AS o
INNER JOIN nakheel.order_items AS i
  ON o.order_id = i.order_id;

-- Bonus: the order whose total was copied onto the most rows.
-- @check Bonus
SELECT o.order_id, o.order_total, COUNT(*) AS copies
FROM nakheel.orders AS o
INNER JOIN nakheel.order_items AS i
  ON o.order_id = i.order_id
GROUP BY o.order_id, o.order_total
ORDER BY copies DESC, o.order_id
LIMIT 1;
