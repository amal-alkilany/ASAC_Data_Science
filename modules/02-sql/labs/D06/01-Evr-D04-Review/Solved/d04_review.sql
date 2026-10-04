-- D06 · 1.2 Everyone Do: D04 in one query
-- Review of D04 before joins: say what one row is, predict the row count, then run.

-- 1. One row of nakheel.orders is one order. (1 row: 3,000 rows and 3,000 different orders)
-- @check 1
SELECT COUNT(*) AS order_rows,
       COUNT(DISTINCT order_id) AS different_orders
FROM nakheel.orders;

-- 2. The planned dead end: a column that is neither grouped nor aggregated.
-- BigQuery stops: "SELECT list expression references column channel which is neither grouped nor aggregated".
-- @skip
SELECT channel, SUM(order_total) AS revenue
FROM nakheel.orders;

-- 3. The fix: one row per channel. Completed orders only. (2 rows)
-- @check 3
SELECT channel,
       COUNT(*) AS completed_orders,
       ROUND(SUM(order_total), 2) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY channel
ORDER BY channel;

-- 4. Add the D04 size rule as a CASE and group by it too: one row per channel and band. (6 rows)
-- @check 4
SELECT channel,
       CASE
         WHEN order_total >= 200 THEN 'large'
         WHEN order_total >= 50 THEN 'medium'
         ELSE 'small'
       END AS size_band,
       COUNT(*) AS completed_orders,
       ROUND(SUM(order_total), 2) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY channel, size_band
ORDER BY channel, revenue DESC;

-- 5. Keep only the groups worth more than 50,000: a test on groups, so HAVING. (3 rows)
-- @check 5
SELECT channel,
       CASE
         WHEN order_total >= 200 THEN 'large'
         WHEN order_total >= 50 THEN 'medium'
         ELSE 'small'
       END AS size_band,
       COUNT(*) AS completed_orders,
       ROUND(SUM(order_total), 2) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY channel, size_band
HAVING SUM(order_total) > 50000
ORDER BY revenue DESC;
