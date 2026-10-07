-- D03 · 4.4 Everyone Do: filter rows
-- Before each query: one row of the table is one ___ ? How many rows will come back?

-- 1. Customers in Irbid.


-- 2. Orders placed on or after 15 August 2026.


-- 3. Order lines with a quantity of 2 or more, largest quantity first.


-- 4. Try this one and read the error message. Why does it fail? Then fix it.
SELECT order_id AS order_number, status
FROM D03.orders
WHERE order_number = 1003;
