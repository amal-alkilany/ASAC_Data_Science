-- D04 · 4.2 Everyone Do: dates
-- Table: nakheel.orders. One row is one order.

-- 1. EXTRACT takes one part of a date. Orders per year. (3 rows: 2024 has only four months)
-- @check 1
SELECT EXTRACT(YEAR FROM order_date) AS year,
       COUNT(*) AS orders
FROM nakheel.orders
GROUP BY year
ORDER BY year;

-- 2. DATE_TRUNC keeps the date but moves it to the start of the month. (24 rows)
-- @check 2
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       COUNT(*) AS orders
FROM nakheel.orders
GROUP BY month
ORDER BY month;

-- 3. FORMAT_DATE turns a date into text in the shape you choose. %A is the weekday name.
--    Which weekday is quietest? (7 rows: Friday, 357)
-- @check 3
SELECT FORMAT_DATE('%A', order_date) AS weekday,
       COUNT(*) AS orders
FROM nakheel.orders
GROUP BY weekday
ORDER BY orders DESC;
