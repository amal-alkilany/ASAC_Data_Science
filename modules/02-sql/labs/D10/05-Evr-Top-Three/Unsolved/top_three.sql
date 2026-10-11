-- D10 · 3.2 Everyone Do: The top three in every category

-- One row per product: completed revenue. (56 rows)
WITH product_revenue AS (
  SELECT p.category,
         p.product_name,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
  GROUP BY p.category, p.product_name
)
SELECT *
FROM product_revenue;

-- 1. Rank the products inside each category by revenue.


-- 2. Keep the top three: a second CTE, ranked, then WHERE.


-- 3. The same with QUALIFY.

