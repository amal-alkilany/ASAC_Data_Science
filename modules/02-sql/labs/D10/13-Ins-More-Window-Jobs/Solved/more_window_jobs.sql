-- D10 · 4.2 Instructor Do: Four more jobs for a window
-- Four short queries, one per job. Paste them; the class has seen every part already.

-- 2. One row per person: Omar Nasser of Irbid has two accounts, C-1204 (3 completed orders)
--    and C-1401 (18). Keep the account with more completed orders. (499 rows from 500 accounts)
-- @check 2
WITH completed AS (
  SELECT customer_id,
         COUNT(*) AS completed_orders
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
),
customer_orders AS (
  SELECT c.customer_id,
         c.customer_name,
         c.city,
         COALESCE(x.completed_orders, 0) AS completed_orders
  FROM nakheel.customers AS c
  LEFT JOIN completed AS x
    ON c.customer_id = x.customer_id
)
SELECT customer_id,
       customer_name,
       city,
       completed_orders
FROM customer_orders
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_name, city
                           ORDER BY completed_orders DESC, customer_id) = 1
ORDER BY customer_id;

-- 2, latest order. The same pattern: each customer's most recent completed order.
--    (452 rows: one per customer with a completed order)
-- @check 2, latest order
SELECT customer_id,
       order_id,
       order_date,
       order_total
FROM nakheel.orders
WHERE status = 'completed'
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id
                           ORDER BY order_date DESC, order_id DESC) = 1
ORDER BY customer_id;

-- 3. Time between events: days since the same customer's previous completed order.
--    (2,771 rows; each customer's first order has no previous order, so its gap is NULL)
-- @check 3
WITH with_previous AS (
  SELECT customer_id,
         order_id,
         order_date,
         LAG(order_date) OVER (PARTITION BY customer_id
                               ORDER BY order_date, order_id) AS previous_order_date
  FROM nakheel.orders
  WHERE status = 'completed'
)
SELECT customer_id,
       order_id,
       order_date,
       previous_order_date,
       DATE_DIFF(order_date, previous_order_date, DAY) AS days_since_previous
FROM with_previous
ORDER BY customer_id, order_date, order_id;

-- 3, summary. How many gaps, and how long on average? (1 row: 2,771 orders, 2,319 gaps, 60.8 days)
-- @check 3, summary
WITH with_previous AS (
  SELECT customer_id,
         order_id,
         order_date,
         LAG(order_date) OVER (PARTITION BY customer_id
                               ORDER BY order_date, order_id) AS previous_order_date
  FROM nakheel.orders
  WHERE status = 'completed'
),
gaps AS (
  SELECT DATE_DIFF(order_date, previous_order_date, DAY) AS days_since_previous
  FROM with_previous
)
SELECT COUNT(*) AS orders,
       COUNT(days_since_previous) AS gaps,
       ROUND(AVG(days_since_previous), 1) AS average_gap_days
FROM gaps;

-- 4. Buckets: the 452 buying customers in four equal groups by revenue, and each group's share.
--    (4 rows of 113 customers; the top quarter brings 254,613.00, 80.6%; the bottom 1.8%)
-- @check 4
WITH customer_revenue AS (
  SELECT customer_id,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
),
quartiles AS (
  SELECT customer_id,
         revenue,
         NTILE(4) OVER (ORDER BY revenue DESC, customer_id) AS quartile,
         100 * revenue / SUM(revenue) OVER () AS share_pct
  FROM customer_revenue
)
SELECT quartile,
       COUNT(*) AS customers,
       ROUND(SUM(revenue), 2) AS revenue,
       ROUND(SUM(share_pct), 1) AS share_pct
FROM quartiles
GROUP BY quartile
ORDER BY quartile;

-- 5. A moving average: each month with the two months before it.
--    (24 rows; April 2026 20,237.00 on its own, 16,016.00 smoothed)
-- @check 5
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
)
SELECT month,
       revenue,
       ROUND(AVG(revenue) OVER (ORDER BY month
                                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3m
FROM monthly
ORDER BY month;
