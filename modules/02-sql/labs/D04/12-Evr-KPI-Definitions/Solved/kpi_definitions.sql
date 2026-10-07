-- D04 · 5.1 Everyone Do: three KPIs, each defined before it is calculated
--
-- | KPI                  | Rule in words                                          | Grain (one row is)  |
-- |----------------------|--------------------------------------------------------|---------------------|
-- | Completed revenue    | Sum of order_total for completed orders                | one calendar month  |
-- | Completed orders     | Number of completed orders                             | one calendar month  |
-- | Average order value  | Completed revenue divided by completed orders          | one calendar month  |
--
-- All three share a grain, so one query returns them side by side.
-- @check 1
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       ROUND(SUM(order_total), 2) AS completed_revenue,
       COUNT(*) AS completed_orders,
       ROUND(SUM(order_total) / COUNT(*), 2) AS average_order_value
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY month
ORDER BY month;

-- Step 3: read the August 2025 and August 2026 rows of the result above.
-- August 2025: 13,075.50 from 126 orders, average 103.77.
-- August 2026: 13,061.50 from 129 orders, average 101.25.
-- Revenue is almost flat (14.00 lower), completed orders are up by 3, and the
-- average order is 2.52 smaller. All three moved a little, in different directions,
-- which is why the definition table keeps them as three separate KPIs.
