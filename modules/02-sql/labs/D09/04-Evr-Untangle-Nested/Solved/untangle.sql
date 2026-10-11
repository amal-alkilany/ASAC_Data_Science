-- D09 · 3.7 Everyone Do: Untangle a nested query

-- 1, nested. (2 rows: came back 323, one order 129)
SELECT CASE
         WHEN completed_orders = 1 THEN 'one order'
         ELSE 'came back'
       END AS kind,
       COUNT(*) AS customers
FROM (SELECT customer_id,
             COUNT(*) AS completed_orders
      FROM nakheel.orders
      WHERE status = 'completed'
      GROUP BY customer_id) AS per_customer
GROUP BY kind
ORDER BY kind;

-- 1, as a CTE. (The same 2 rows)
-- @check 1, nested and CTE
WITH per_customer AS (
  SELECT customer_id,
         COUNT(*) AS completed_orders
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
)
SELECT CASE
         WHEN completed_orders = 1 THEN 'one order'
         ELSE 'came back'
       END AS kind,
       COUNT(*) AS customers
FROM per_customer
GROUP BY kind
ORDER BY kind;

-- 2, nested: the monthly query written twice. (8 rows; April 2026, 20,237.00)
SELECT month,
       ROUND(revenue, 2) AS revenue
FROM (SELECT DATE_TRUNC(order_date, MONTH) AS month,
             SUM(order_total) AS revenue
      FROM nakheel.orders
      WHERE status = 'completed'
      GROUP BY month) AS monthly
WHERE revenue > (SELECT AVG(revenue)
                 FROM (SELECT DATE_TRUNC(order_date, MONTH) AS month,
                              SUM(order_total) AS revenue
                       FROM nakheel.orders
                       WHERE status = 'completed'
                       GROUP BY month) AS monthly_again)
ORDER BY month;

-- 2, as one CTE read twice. (The same 8 rows)
-- @check 2, nested and CTE
WITH monthly AS (
  SELECT DATE_TRUNC(order_date, MONTH) AS month,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY month
)
SELECT month,
       ROUND(revenue, 2) AS revenue
FROM monthly
WHERE revenue > (SELECT AVG(revenue) FROM monthly)
ORDER BY month;

-- Bonus: the biggest customer's name, as two CTEs. (1 row: C-1380, Leen Najjar)
WITH customer_revenue AS (
  SELECT customer_id,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
),
top_customer AS (
  SELECT customer_id, revenue
  FROM customer_revenue
  ORDER BY revenue DESC
  LIMIT 1
)
SELECT c.customer_id,
       c.customer_name,
       t.revenue
FROM top_customer AS t
INNER JOIN nakheel.customers AS c
  ON t.customer_id = c.customer_id;
