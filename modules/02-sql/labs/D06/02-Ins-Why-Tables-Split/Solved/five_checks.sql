-- D06 · 2.2 Instructor Do: The Five Checks before you trust a join (D03.orders and D03.customers)
--
-- 1. What is one row in each table?   orders: one order. customers: one customer record.
-- 2. Which key joins them?            orders.customer_id = customers.customer_id
-- 3. Is the key unique on the "one" side?
-- 4. How many rows should come out?
-- 5. What happens to rows with no match?

-- Check 3: customer_id is unique in customers if the two counts are equal. (5 and 5: unique)
-- @check 1
SELECT COUNT(*) AS customer_rows,
       COUNT(DISTINCT customer_id) AS different_ids
FROM D03.customers;

-- On the "many" side it repeats, and that is expected: one customer, many orders. (5 and 3)
-- @check 2
SELECT COUNT(*) AS order_rows,
       COUNT(DISTINCT customer_id) AS different_ids
FROM D03.orders;

-- Check 4: each order finds at most one customer, so an INNER JOIN returns at most 5 rows.
-- Check 5: customers with no orders (C-377, C-455) disappear from an INNER JOIN and stay in a LEFT JOIN.
