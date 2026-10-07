-- D07 · 3.2 Everyone Do: A cleaning rule of your own
-- "Completed revenue by city." City is on customers, typed inconsistently: 'amman', 'Al Zarqa', empty.

-- 1. As typed: 11 spellings, including NULL for customers with no city and for the order with no customer. (11 rows)
-- @check 1
SELECT c.city,
       COUNT(*) AS completed_orders
FROM nakheel.orders AS o
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY c.city
ORDER BY completed_orders DESC;

-- 3. The rule, written as a CASE: no city is 'unknown'; Al Zarqa is Zarqa; everything else is
-- trimmed and lower-cased. Without the IS NULL line, the ELSE line would give NULL, not 'unknown'.
-- No city passes two of these tests, so the IS NULL line could also go second; first is the habit.
-- (9 rows: amman first, 1,064 orders and 130,848.00; unknown 37 orders and 3,197.00)
-- @check 3
SELECT CASE
         WHEN c.city IS NULL THEN 'unknown'
         WHEN LOWER(TRIM(c.city)) = 'al zarqa' THEN 'zarqa'
         ELSE LOWER(TRIM(c.city))
       END AS city_clean,
       COUNT(*) AS completed_orders,
       ROUND(SUM(o.order_total), 2) AS revenue
FROM nakheel.orders AS o
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY city_clean
ORDER BY revenue DESC;
