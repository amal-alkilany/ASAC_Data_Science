-- D10 · 3.1 Instructor Do: Rank within a group, and what a tie does

-- 1. Units per Sportswear product. (9 rows; Water bottle 608 first; two products on 284)
-- @check 1
WITH product_units AS (
  SELECT p.category,
         p.product_name,
         SUM(i.qty) AS units
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
  GROUP BY p.category, p.product_name
)
SELECT *
FROM product_units
WHERE category = 'Sportswear'
ORDER BY units DESC;

-- 2-3. Three ways to number; ROW_NUMBER made repeatable with a second sort column.
--      (9 rows; Football jersey 8, 8, 7)
-- @check 2
WITH product_units AS (
  SELECT p.category,
         p.product_name,
         SUM(i.qty) AS units
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
  GROUP BY p.category, p.product_name
)
SELECT product_name,
       units,
       ROW_NUMBER() OVER (ORDER BY units DESC, product_name) AS row_num,
       RANK()       OVER (ORDER BY units DESC) AS rank_num,
       DENSE_RANK() OVER (ORDER BY units DESC) AS dense_num
FROM product_units
WHERE category = 'Sportswear'
ORDER BY units DESC, product_name;

-- 4. Every category: PARTITION BY restarts the numbering. (56 rows)
-- @check 4
WITH product_units AS (
  SELECT p.category,
         p.product_name,
         SUM(i.qty) AS units
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
       units,
       RANK() OVER (PARTITION BY category ORDER BY units DESC) AS rank_num
FROM product_units
ORDER BY category, rank_num;
