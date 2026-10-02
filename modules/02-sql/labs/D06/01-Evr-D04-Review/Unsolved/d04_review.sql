-- D06 · 1.2 Everyone Do: D04 in one query
-- Before each query: say what one row of the result is, predict the row count, then run.

-- 1. One row of nakheel.orders is one ___? Count the rows and the different order_id values.
--    Predict both numbers first.


-- 2. "Revenue by channel." Run this exactly as written and read the result.
SELECT channel, SUM(order_total) AS revenue
FROM nakheel.orders;


-- 3. Fix query 2: completed orders only, one row per channel, with the number of orders
--    and the revenue rounded to 2 decimals. One row is one ___? How many rows?


-- 4. Add the D04 size rule as a CASE and group by it too:
--    'large' from 200, 'medium' from 50, otherwise 'small'.
--    One row is one ___? How many rows?


-- 5. Keep only the groups worth more than 50,000. WHERE or HAVING?

