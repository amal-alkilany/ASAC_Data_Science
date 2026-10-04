-- D04 · 4.1 Instructor Do: write the rule in words, then as CASE
-- Rule: an order is "large" from 200 dinars, "medium" from 50, otherwise "small".
-- CASE checks the WHEN lines from the top and stops at the first true one.

-- The rule as a new column on every order. (The first 10 of 3,000 orders.)
-- @check 1
SELECT order_id, order_total,
       CASE
         WHEN order_total >= 200 THEN 'large'
         WHEN order_total >= 50 THEN 'medium'
         ELSE 'small'
       END AS size_band
FROM nakheel.orders
ORDER BY order_id
LIMIT 10;

-- Then group by the new column: completed orders per band. (3 rows)
-- @check 2
SELECT CASE
         WHEN order_total >= 200 THEN 'large'
         WHEN order_total >= 50 THEN 'medium'
         ELSE 'small'
       END AS size_band,
       COUNT(*) AS completed_orders,
       ROUND(SUM(order_total), 2) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY size_band
ORDER BY revenue DESC;
