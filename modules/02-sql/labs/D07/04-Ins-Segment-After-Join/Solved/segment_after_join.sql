-- D07 · 3.1 Instructor Do: Group by a column from the other table
-- "Completed revenue by customer segment." The amount is on orders; the segment is on customers.

-- 1. Audit before: completed orders on orders alone. (1 row: 2,771 orders; 316,023.50)
-- @check 1
SELECT COUNT(*) AS completed_orders,
       ROUND(SUM(order_total), 2) AS revenue
FROM nakheel.orders
WHERE status = 'completed';

-- 2. Audit after INNER JOIN customers: one order is lost. (1 row: 2,770; 315,085.50)
-- @check 2
SELECT COUNT(*) AS completed_orders,
       ROUND(SUM(o.order_total), 2) AS revenue
FROM nakheel.orders AS o
INNER JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed';

-- 3. LEFT JOIN keeps every order; the segment typed five ways is cleaned with the D04 functions,
-- and the order with no customer is labelled 'unknown'. (3 rows: retail 160,881.50;
-- wholesale 154,204.00; unknown 938.00. Together 316,023.50.)
-- @check 3
SELECT COALESCE(LOWER(TRIM(c.segment)), 'unknown') AS segment_clean,
       COUNT(*) AS completed_orders,
       ROUND(SUM(o.order_total), 2) AS revenue
FROM nakheel.orders AS o
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY segment_clean
ORDER BY revenue DESC;
