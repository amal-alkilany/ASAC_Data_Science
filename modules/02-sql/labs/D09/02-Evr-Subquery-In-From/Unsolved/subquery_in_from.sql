-- D09 · 2.2 Everyone Do: Do our customers come back?
-- One row per order is the data; one row per customer is what the question needs.

-- 1. Step 1 alone: completed orders per customer, most first.
--    One row is one ___? How many rows?


-- 2. The shortcut that does not work. Run it and read the error.
SELECT AVG(COUNT(*)) AS avg_orders
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY customer_id;

-- 3. Step 1 in FROM: the average, fewest and most completed orders per customer.
SELECT
FROM (

     ) AS per_customer;

-- 4. How many customers bought once, and how many came back?

