-- D08 · 5.1 Everyone Do: Prove the views give the numbers you know

-- 1. Completed revenue by category, from the views. Must match D06's answer. (6 rows: Outerwear first, 76,637.00)
-- @check 1
SELECT p.category,
       ROUND(SUM(f.revenue), 2) AS revenue
FROM bi.fact_sales AS f
INNER JOIN bi.dim_product AS p
  ON f.product_id = p.product_id
WHERE f.status = 'completed'
GROUP BY p.category
ORDER BY revenue DESC;

-- 2. Completed revenue by segment, LEFT JOIN. Must match D07 3.1. (3 rows: retail 160,881.50; wholesale 154,204.00; NULL 938.00)
-- @check 2
SELECT c.segment,
       ROUND(SUM(f.revenue), 2) AS revenue
FROM bi.fact_sales AS f
LEFT JOIN bi.dim_customer AS c
  ON f.customer_id = c.customer_id
WHERE f.status = 'completed'
GROUP BY c.segment
ORDER BY revenue DESC;

-- 3. The audit with INNER JOIN: the orphan order's 5 lines are gone. (1 row: 6,946 lines; 315,085.50)
-- Power BI meets the same order when it relates these tables (D18).
-- @check 3
SELECT COUNT(*) AS line_rows,
       ROUND(SUM(f.revenue), 2) AS revenue
FROM bi.fact_sales AS f
INNER JOIN bi.dim_customer AS c
  ON f.customer_id = c.customer_id
WHERE f.status = 'completed';
