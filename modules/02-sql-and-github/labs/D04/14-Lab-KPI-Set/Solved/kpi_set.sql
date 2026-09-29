-- ============================================================
-- D04 Lab · A KPI set for Nakheel Retail · SOLVED
-- Tables: nakheel.orders (one row is one order)
-- ============================================================
--
-- KPI definition table
-- | # | KPI                       | Rule in words                                              | Grain (one row is) |
-- |---|---------------------------|------------------------------------------------------------|--------------------|
-- | 1 | Completed revenue         | Sum of order_total, completed orders                       | one month          |
-- | 2 | Completed orders          | Count of completed orders                                  | one month          |
-- | 3 | Average order value       | Completed revenue / completed orders                       | one channel        |
-- | 4 | Cancellation rate         | Cancelled orders / all orders placed                       | one month          |
-- | 5 | High-cancellation months  | Months where the cancellation rate is above 9%             | one month          |

-- ============================================================
-- C1 · KPIs 1 and 2 by month
-- One row is: one month
-- Result check: 24 rows; Aug 2026 revenue 13,061.50 from 129 orders
-- ============================================================
-- @check C1
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       ROUND(SUM(order_total), 2) AS completed_revenue,
       COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY month
ORDER BY month;

-- ============================================================
-- C1 · KPI 3, average order value by channel
-- One row is: one channel
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
-- C2 · KPI 4, cancellation rate by month (conditional aggregate)
-- One row is: one month
-- ============================================================
-- @check C2
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       COUNT(*) AS orders_placed,
       COUNTIF(status = 'cancelled') AS cancelled,
       ROUND(AVG(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END), 4) AS cancellation_rate
FROM nakheel.orders
GROUP BY month
ORDER BY month;

-- ============================================================
-- C2 · KPI 5, months with a cancellation rate above 9% (HAVING)
-- One row is: one month
-- ============================================================
-- @check C2b
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       ROUND(AVG(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END), 4) AS cancellation_rate
FROM nakheel.orders
GROUP BY month
HAVING AVG(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) > 0.09
ORDER BY month;

-- ============================================================
-- C3 · "Is the typical order getting bigger?"
-- First try: average order value by year.
-- One row is: one calendar year
-- ============================================================
-- @check C3a
SELECT EXTRACT(YEAR FROM order_date) AS year,
       ROUND(AVG(order_total), 2) AS average_order_value,
       COUNT(*) AS completed_orders,
       COUNT(DISTINCT DATE_TRUNC(order_date, MONTH)) AS months_of_data
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY year
ORDER BY year;

-- Second try: the same KPI by month.
-- One row is: one month
-- @check C3b
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       ROUND(AVG(order_total), 2) AS average_order_value
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY month
ORDER BY month;

-- Third try: compare like with like. September to August, twice.
-- One row is: one 12-month period
-- @check C3c
SELECT CASE WHEN order_date < '2025-09-01' THEN 'Sep 2024 - Aug 2025'
            ELSE 'Sep 2025 - Aug 2026' END AS period,
       ROUND(AVG(order_total), 2) AS average_order_value,
       COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY period
ORDER BY period;

-- ============================================================
-- Stretch card (not checked): read the bytes estimate first, then run.
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
-- @check M1
SELECT product_id, SUM(qty) AS units
FROM nakheel.order_items
GROUP BY product_id
ORDER BY units DESC, product_id
LIMIT 10;

-- M2 How many completed orders were delivered on the day they were placed?
-- @check M2
SELECT COUNTIF(delivered_date = order_date) AS same_day,
       COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed';

-- M3 Shipping fees collected per year, completed orders.
-- @check M3
SELECT EXTRACT(YEAR FROM order_date) AS year,
       ROUND(SUM(shipping_fee), 2) AS shipping_collected
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY year
ORDER BY year;

-- M4 New customer accounts per year.
-- @check M4
SELECT EXTRACT(YEAR FROM signup_date) AS signup_year,
       COUNT(*) AS new_customers
FROM nakheel.customers
GROUP BY signup_year
ORDER BY signup_year;

-- O1 Each country's lowest and highest life expectancy since 1950.
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
