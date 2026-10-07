-- D04 · 2.3 Everyone Do: aggregate functions, checked against the D01 worksheet

-- 1. How many orders? One row in, one number out. (5)
-- @check 1
SELECT COUNT(*) AS orders
FROM D03.orders;

-- 2. COUNT(*) counts rows. COUNT(column) counts rows where that column is not NULL. (5 and 4)
-- @check 2
SELECT COUNT(*) AS customer_rows,
       COUNT(city) AS rows_with_a_city
FROM D03.customers;

-- 3. COUNT(DISTINCT) counts different values. 5 orders, 3 customer IDs. (Two people, as D01 showed.)
-- @check 3
SELECT COUNT(*) AS orders,
       COUNT(DISTINCT customer_id) AS customer_ids
FROM D03.orders;

-- 4. SUM, AVG, MIN, MAX on the order lines. AVG(price) counts every line once, whatever its qty.
-- @check 4
SELECT SUM(qty * price) AS revenue_all_orders,
       ROUND(AVG(price), 2) AS average_unit_price,
       MIN(price) AS cheapest_unit,
       MAX(price) AS most_expensive_unit
FROM D03.order_items;

-- 5. MIN and MAX work on dates too.
-- @check 5
SELECT MIN(order_date) AS first_order,
       MAX(order_date) AS last_order
FROM D03.orders;
