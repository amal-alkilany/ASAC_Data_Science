-- D10 · 2.2 Everyone Do: Each product's share of its category

-- 1. One row per product. (56 rows)
-- @check 1
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

-- 2. The category total on every row. (56 rows; 76,637.00 on every Outerwear row)
-- @check 2
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
SELECT category,
       product_name,
       revenue,
       SUM(revenue) OVER (PARTITION BY category) AS category_revenue
FROM product_revenue;

-- 3. The share. (56 rows; White thobe first, 24.1)
-- @check 3
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
SELECT category,
       product_name,
       revenue,
       SUM(revenue) OVER (PARTITION BY category) AS category_revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (PARTITION BY category), 1) AS share_pct
FROM product_revenue
ORDER BY share_pct DESC;
