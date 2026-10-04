-- D04 · 3.2 Everyone Do: grouping on Nakheel orders
-- Table: nakheel.orders. One row is one order.

-- 1. Orders by status. One row of the result is one status.
-- @check 1
SELECT status, COUNT(*) AS orders
FROM nakheel.orders
GROUP BY status
ORDER BY orders DESC;

-- 2. Completed revenue by month. DATE_TRUNC turns every date into the first day of its month;
--    the date functions come properly in 4.2. One row of the result is one month.
-- @check 2
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       ROUND(SUM(order_total), 2) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY month
ORDER BY month;

-- 3. Three counts on the same rows. Each answers a different question.
-- @check 3
SELECT COUNT(*) AS orders,
       COUNT(delivered_date) AS delivered_orders,
       COUNT(DISTINCT customer_id) AS customers_who_ordered
FROM nakheel.orders;
