-- D09 · 3.8 Everyone Do: Two branches, one answer
-- "Which categories grew most from our first year to our second?"
-- Year 1 = September 2024 to August 2025. Year 2 = September 2025 to August 2026. Completed orders.

-- 1, branch 1 alone: completed revenue per category in year 1. (6 rows; Outerwear first, 36,318.00)
-- @check 1
WITH year_one AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
    AND o.order_date BETWEEN '2024-09-01' AND '2025-08-31'
  GROUP BY p.category
)
SELECT *
FROM year_one
ORDER BY revenue DESC;

-- 1, the year 1 total. (1 row: 142,273.50)
-- @check 1, total
WITH year_one AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
    AND o.order_date BETWEEN '2024-09-01' AND '2025-08-31'
  GROUP BY p.category
)
SELECT SUM(revenue) AS total
FROM year_one;

-- 2, branch 2 alone: the same CTE with year 2's dates. (6 rows; Outerwear first, 40,319.00)
-- @check 2
WITH year_two AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
    AND o.order_date BETWEEN '2025-09-01' AND '2026-08-31'
  GROUP BY p.category
)
SELECT *
FROM year_two
ORDER BY revenue DESC;

-- 2, the year 2 total. (1 row: 173,750.00; with year 1, 316,023.50, every completed sale)
-- @check 2, total
WITH year_two AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
    AND o.order_date BETWEEN '2025-09-01' AND '2026-08-31'
  GROUP BY p.category
)
SELECT SUM(revenue) AS total
FROM year_two;

-- 3, the answer: both branches, joined on category. (6 rows; Shoes first, 37.3; Outerwear last, 11.0)
-- @check 3
WITH year_one AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
    AND o.order_date BETWEEN '2024-09-01' AND '2025-08-31'
  GROUP BY p.category
),
year_two AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
    AND o.order_date BETWEEN '2025-09-01' AND '2026-08-31'
  GROUP BY p.category
)
SELECT y1.category,
       ROUND(y1.revenue, 2) AS year_one_revenue,
       ROUND(y2.revenue, 2) AS year_two_revenue,
       ROUND(100 * (y2.revenue - y1.revenue) / y1.revenue, 1) AS growth_pct
FROM year_one AS y1
INNER JOIN year_two AS y2
  ON y1.category = y2.category
ORDER BY growth_pct DESC;

-- Bonus: growth in money as well as in percent. (6 rows; Shoes added the most, 9,797.50;
-- Sportswear the least, 3,099.00; Outerwear, last in percent, is fourth in money with 4,001.00)
-- @check Bonus
WITH year_one AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
    AND o.order_date BETWEEN '2024-09-01' AND '2025-08-31'
  GROUP BY p.category
),
year_two AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
    AND o.order_date BETWEEN '2025-09-01' AND '2026-08-31'
  GROUP BY p.category
)
SELECT y1.category,
       ROUND(y2.revenue - y1.revenue, 2) AS growth_money,
       ROUND(100 * (y2.revenue - y1.revenue) / y1.revenue, 1) AS growth_pct
FROM year_one AS y1
INNER JOIN year_two AS y2
  ON y1.category = y2.category
ORDER BY growth_money DESC;
