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

-- 2. Three ways to number the rows. (9 rows; Football jersey 8, 8, 7)
--    Gym shorts and Compression top can swap 6 and 7 in row_num between runs.
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
       ROW_NUMBER() OVER (ORDER BY units DESC) AS row_num,
       RANK()       OVER (ORDER BY units DESC) AS rank_num,
       DENSE_RANK() OVER (ORDER BY units DESC) AS dense_num
FROM product_units
WHERE category = 'Sportswear'
ORDER BY units DESC;

-- 3. ROW_NUMBER made repeatable: a second sort column inside OVER.
--    (9 rows; Compression top is always 6 and Gym shorts 7)
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
ORDER BY units DESC;

-- 4. Every category: PARTITION BY restarts the numbering. (56 rows; six products with rank_num 1)
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
       ROW_NUMBER() OVER (PARTITION BY category ORDER BY units DESC, product_name) AS row_num,
       RANK()       OVER (PARTITION BY category ORDER BY units DESC) AS rank_num,
       DENSE_RANK() OVER (PARTITION BY category ORDER BY units DESC) AS dense_num
FROM product_units
ORDER BY category, rank_num, product_name;
