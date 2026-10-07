-- D08 · 2.1 Instructor Do: A question in two steps
-- "Which completed orders are bigger than our average completed order?"

-- Step 1 on its own: the average completed order. (1 row: 114.05)
-- @check 1
SELECT ROUND(AVG(order_total), 2) AS average_order
FROM nakheel.orders
WHERE status = 'completed';

-- Step 2 with the number typed by hand. It works today, and it is wrong the day a new order arrives. (689 rows)
-- @check 2
SELECT order_id, customer_id, order_total
FROM nakheel.orders
WHERE status = 'completed'
  AND order_total > 114.05
ORDER BY order_total DESC;

-- The same question with step 1 inside step 2: a subquery. BigQuery runs the inner query first,
-- gets one number, and uses it in the WHERE. (689 rows; order 100849, 1,964.50, first)
-- @check 3
SELECT order_id, customer_id, order_total
FROM nakheel.orders
WHERE status = 'completed'
  AND order_total > (SELECT AVG(order_total)
                     FROM nakheel.orders
                     WHERE status = 'completed')
ORDER BY order_total DESC;
