-- D10 · 3.2 Everyone Do: The top three in every category

-- 1. Rank inside each category. (56 rows; Denim jacket rank 1 in Outerwear, 12,818.00)
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
SELECT category,
       product_name,
       revenue,
       RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS revenue_rank
FROM product_revenue;

-- 2. The top three, the long way: a second CTE, then WHERE. (18 rows)
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
),
ranked AS (
  SELECT category,
         product_name,
         revenue,
         RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS revenue_rank
  FROM product_revenue
)
SELECT category, product_name, revenue, revenue_rank
FROM ranked
WHERE revenue_rank <= 3
ORDER BY category, revenue_rank;

-- 3. The same with QUALIFY. (18 rows)
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
       RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS revenue_rank
FROM product_revenue
QUALIFY revenue_rank <= 3
ORDER BY category, revenue_rank;
