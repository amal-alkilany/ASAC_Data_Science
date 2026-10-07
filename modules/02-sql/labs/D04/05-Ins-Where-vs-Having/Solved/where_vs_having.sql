-- D04 · 3.3 Instructor Do: WHERE filters rows, HAVING filters groups
-- Run order: FROM, WHERE, GROUP BY, HAVING, SELECT, ORDER BY, LIMIT

-- WHERE removes rows before they are grouped: completed orders per channel.
-- @check 1
SELECT channel, COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY channel
ORDER BY channel;

-- HAVING removes groups after they are counted: customers with more than 20 orders.
-- @check 2
SELECT customer_id, COUNT(*) AS orders
FROM nakheel.orders
GROUP BY customer_id
HAVING COUNT(*) > 20
ORDER BY orders DESC, customer_id;

-- Both in one query: customers with more than 20 completed orders.
-- @check 3
SELECT customer_id, COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY customer_id
HAVING COUNT(*) > 20
ORDER BY completed_orders DESC, customer_id;

-- The error: WHERE runs before the counting, so there is no count to test yet.
-- Error: Aggregate function COUNT not allowed in WHERE clause
-- @skip fails on purpose
SELECT customer_id, COUNT(*) AS orders
FROM nakheel.orders
WHERE COUNT(*) > 20
GROUP BY customer_id;
