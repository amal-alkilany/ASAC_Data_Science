-- D09 · 3.7 Everyone Do: Untangle a nested query
-- Recipe: find the innermost brackets; move them to WITH <name> AS ( ... ); write the name where they were; run and compare.

-- 1. Nested: bought once, or came back? Run it and note the answer.
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

-- 1, as a CTE named per_customer:


-- 2. Nested: months better than the average month. The monthly query is written twice.
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

-- 2, as one CTE named monthly, read twice:


-- Bonus: the biggest customer's name, as two CTEs.

