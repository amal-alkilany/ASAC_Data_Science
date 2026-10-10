-- ============================================================
-- D04 Lab · A KPI set for Nakheel Retail · SOLUTION
-- Table: nakheel.orders (one row is one order)
--
-- Compare this file with your own. Your SQL does not have to match
-- line by line: if your query returns the same rows and values, it
-- is correct. Where there is more than one good way to write a
-- query, both are shown.
-- ============================================================
--
-- KPI definition table
-- | # | KPI                       | Rule in words                                              | Grain (one row is) |
-- |---|---------------------------|------------------------------------------------------------|--------------------|
-- | 1 | Completed revenue         | Sum of order_total, completed orders                       | one month          |
-- | 2 | Completed orders          | Count of completed orders                                  | one month          |
-- | 3 | Average order value       | Completed revenue / completed orders                       | one channel        |
--   (KPI 3: AVG(order_total) on completed orders gives the same number as
--   SUM(order_total) / COUNT(*) with the same WHERE.)
-- | 4 | Cancellation rate         | Cancelled orders / all orders placed                       | one month          |
-- | 5 | High-cancellation months  | Months where the cancellation rate is above 9%             | one month          |

-- ============================================================
-- C1a · KPIs 1 and 2 by month
-- One row is: one month
-- Result check: 24 rows; August 2026: 13,061.50 from 129 orders
-- Interpretation: monthly revenue goes from about 9,800 to 20,200.
-- It mostly rises and falls with the number of completed orders,
-- which goes from 83 to 158 a month.
--
-- Both KPIs count completed orders only, so the filter goes in
-- WHERE, before the rows are grouped into months.
-- ============================================================
-- @check C1a
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       ROUND(SUM(order_total), 2) AS completed_revenue,
       COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY month
ORDER BY month;

-- ============================================================
-- C1b · KPI 3, average order value by channel
-- One row is: one channel
-- Result check: 2 rows; online 109.81, store 116.47
-- Interpretation: a completed store order is worth about 6.66 more
-- than a completed online order.
-- ============================================================
-- @check C1b
SELECT channel,
       ROUND(AVG(order_total), 2) AS average_order_value,
       COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY channel
ORDER BY channel;

-- ============================================================
-- C2a · KPI 4, cancellation rate by month
-- One row is: one month
-- Result check: 24 rows; January 2025: 12 of 116 cancelled, 0.1034
-- Interpretation: about 1 order in 14 is cancelled. The rate moves
-- up and down from month to month, with no clear trend.
--
-- Why there is no WHERE here: WHERE status = 'cancelled' would keep
-- only the cancelled orders. COUNT(*) would then count the same rows
-- as COUNTIF, and every month's rate would be 1. To divide by all
-- orders placed, all orders have to stay in the query.
-- ============================================================

-- Way 1: divide cancelled orders by all orders.
-- This reads the same as the rule in words. In BigQuery, / always
-- returns a decimal, so 12 / 116 gives 0.1034, not 0.
-- @check C2a
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       COUNT(*) AS orders_placed,
       COUNTIF(status = 'cancelled') AS cancelled,
       ROUND(COUNTIF(status = 'cancelled') / COUNT(*), 4) AS cancellation_rate
FROM nakheel.orders
GROUP BY month
ORDER BY month;

-- Way 2: the average of a 0/1 column.
-- The CASE turns each cancelled order into 1 and every other order
-- into 0. The average of those 1s and 0s is the share of orders that
-- were cancelled. For January 2025: twelve 1s and 104 0s, and
-- 12 / 116 = 0.1034, the same answer as Way 1.
-- You will see this pattern in other people's SQL, and it also works
-- in databases that do not have COUNTIF.
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       COUNT(*) AS orders_placed,
       COUNTIF(status = 'cancelled') AS cancelled,
       ROUND(AVG(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END), 4) AS cancellation_rate
FROM nakheel.orders
GROUP BY month
ORDER BY month;

-- ============================================================
-- C2b · KPI 5, months with a cancellation rate above 9%
-- One row is: one month
-- Result check: 6 rows; March 2025 is the highest, 0.1111
-- Interpretation: 6 of the 24 months had a rate above 9%. March 2025
-- had the highest rate: 14 of 126 orders were cancelled.
--
-- Why HAVING and not WHERE: the rate does not exist until the orders
-- are grouped into months. WHERE filters single orders before the
-- grouping; HAVING filters whole groups after it.
-- ============================================================

-- Way 1: repeat the calculation inside HAVING.
-- This works in every SQL database.
-- @check C2b
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       ROUND(COUNTIF(status = 'cancelled') / COUNT(*), 4) AS cancellation_rate
FROM nakheel.orders
GROUP BY month
HAVING COUNTIF(status = 'cancelled') / COUNT(*) > 0.09
ORDER BY month;

-- Way 2: use the column name from SELECT inside HAVING.
-- It is shorter, and BigQuery accepts it. Some databases, such as
-- SQL Server, do not, so Way 1 is the version that works everywhere.
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       ROUND(COUNTIF(status = 'cancelled') / COUNT(*), 4) AS cancellation_rate
FROM nakheel.orders
GROUP BY month
HAVING cancellation_rate > 0.09
ORDER BY month;

-- ============================================================
-- C3 · "Is the typical order getting bigger?"
-- ============================================================

-- C3a: average order value by year, with the months of data in each year.
-- One row is: one calendar year
-- Result check: 3 rows; 2024: 116.08 from 4 months of data;
-- 2025: 110.39 from 12; 2026: 117.98 from 8
--
-- First read: the average falls to 110.39 in 2025, then rises to 117.98
-- in 2026. Read alone, this says "yes, orders are getting bigger".
--
-- Then: the months_of_data column shows the years are not the same
-- size. The data starts in September 2024 and ends in August 2026,
-- so 2024 holds only September to December, 2026 holds only January
-- to August, and only 2025 is a full year. Each year covers
-- different months, so the three averages are not a fair comparison.
-- @check C3a
SELECT EXTRACT(YEAR FROM order_date) AS year,
       ROUND(AVG(order_total), 2) AS average_order_value,
       COUNT(*) AS completed_orders,
       COUNT(DISTINCT DATE_TRUNC(order_date, MONTH)) AS months_of_data
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY year
ORDER BY year;

-- C3b: the same KPI by month.
-- One row is: one month
-- Result check: 24 rows; September 2024: 100.61
-- The monthly values go up and down between about 93 and 152, with
-- no steady direction. April 2026 (147.72) and June 2026 (151.94)
-- are unusually high, and they pull the 2026 yearly average up.
-- @check C3b
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       ROUND(AVG(order_total), 2) AS average_order_value
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY month
ORDER BY month;

-- C3c: compare like with like, September to August, twice.
-- One row is: one 12-month period
-- Result check: 2 rows; 115.20, then 113.12
--
-- The CASE gives every order a label: orders before 1 September 2025
-- get the first period, all later orders get the second. GROUP BY
-- then makes one row per label, so both periods appear side by side
-- in one result.
-- @check C3c
SELECT CASE WHEN order_date < '2025-09-01' THEN 'Sep 2024 - Aug 2025'
            ELSE 'Sep 2025 - Aug 2026' END AS period,
       ROUND(AVG(order_total), 2) AS average_order_value,
       COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY period
ORDER BY period;

-- Why not use WHERE on the dates?
-- You could, and the numbers would be correct. But WHERE keeps the
-- rows of one period and drops the rest, so one query gives you one
-- period. You would run the query below, change the dates, run it
-- again, and compare the two results yourself.
-- Use WHERE to remove rows you do not need. Use CASE with GROUP BY
-- when you want to compare groups in one result.
SELECT ROUND(AVG(order_total), 2) AS average_order_value,
       COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed'
  AND order_date BETWEEN '2024-09-01' AND '2025-08-31';
-- Second run: change the dates to '2025-09-01' AND '2026-08-31'.

-- C3d, interpretation:
-- The 12-month comparison answers the manager's question, because
-- both periods cover the same twelve months of the year. The typical
-- completed order went from 115.20 to 113.12: it is not getting
-- bigger, it stayed about the same and fell slightly. The yearly
-- result suggested growth only because 2024 and 2026 are part years
-- that cover different months.

-- ============================================================
-- Stretch card (not checked): read the bytes estimate before you run.
-- The counts change as the public dataset is updated.
-- ============================================================
-- @skip public dataset
SELECT status, COUNT(*) AS orders
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY status
ORDER BY orders DESC;

-- ============================================================
-- More practice (not checked, not submitted)
-- ============================================================

-- M1 The ten products with the most units sold (all statuses).
-- Result check: 10 rows; P-040 first, 656 units
-- product_id in ORDER BY decides the order when two products sold
-- the same number of units.
-- @check M1
SELECT product_id, SUM(qty) AS units
FROM nakheel.order_items
GROUP BY product_id
ORDER BY units DESC, product_id
LIMIT 10;

-- M2 How many completed orders were delivered on the day they were placed?
-- Result check: 1 row; 1,763 of 2,771
-- COUNTIF counts the same-day orders while COUNT(*) counts all
-- completed orders, so you get both numbers in one row.
-- @check M2
SELECT COUNTIF(delivered_date = order_date) AS same_day,
       COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed';

-- M3 Shipping fees collected per year, completed orders.
-- Result check: 3 rows; 2025: 502.50
-- As in C3a, 2024 and 2026 are part years, so do not compare the
-- three totals directly.
-- @check M3
SELECT EXTRACT(YEAR FROM order_date) AS year,
       ROUND(SUM(shipping_fee), 2) AS shipping_collected
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY year
ORDER BY year;

-- M4 New customer accounts per year.
-- Result check: 4 rows; 2024: 292 new accounts
-- The year comes from signup_date, so 2023 appears here: some
-- customers opened an account before the orders data starts.
-- @check M4
SELECT EXTRACT(YEAR FROM signup_date) AS signup_year,
       COUNT(*) AS new_customers
FROM nakheel.customers
GROUP BY signup_year
ORDER BY signup_year;

-- O1 Each country's lowest and highest life expectancy since 1950.
-- Result check: 237 rows; Afghanistan: 28.1563 to 66.0346
-- The WHERE keeps countries and territories only, as in the D03 lab.
-- Regions such as "Americas" have no code. Groups such as "World"
-- and "Africa" have a code that starts with OWID. Kosovo is the one
-- country with an OWID code (OWID_KOS), so it is added back.
-- @check O1
SELECT entity,
       MIN(life_expectancy) AS lowest,
       MAX(life_expectancy) AS highest
FROM owid.life_expectancy_data
WHERE code IS NOT NULL
  AND (code NOT LIKE 'OWID%' OR code = 'OWID_KOS')
GROUP BY entity
ORDER BY entity;

-- O2 The average across countries in 2023, against the World row.
-- Result check: 74.15 across 237 countries; World: 73.1694
-- Why they differ: the plain average counts every country once, so a
-- small island counts as much as India or China. The World figure
-- counts every person, so countries with large populations weigh
-- more. India (72.0), Indonesia (71.1), Pakistan (67.6) and Nigeria
-- (54.5) are all below 74.15 and have very large populations, so
-- they pull the World figure down.
-- @check O2
SELECT ROUND(AVG(life_expectancy), 2) AS average_of_countries,
       COUNT(*) AS countries
FROM owid.life_expectancy_data
WHERE year = 2023
  AND code IS NOT NULL
  AND (code NOT LIKE 'OWID%' OR code = 'OWID_KOS');

-- @check O2b
SELECT entity, life_expectancy
FROM owid.life_expectancy_data
WHERE year = 2023
  AND entity = 'World';
