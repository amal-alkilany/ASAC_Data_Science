-- D09 · 3.5 Partner Do: Plan the steps, then write them

-- 1, step 1: completed revenue per category. (6 rows; Outerwear first, 76,637.00)
-- @check 1, step 1
WITH category_revenue AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
  GROUP BY p.category
)
SELECT *
FROM category_revenue
ORDER BY revenue DESC;

-- 1, step 2: the average category. (1 row: 52,670.58)
-- @check 1, step 2
WITH category_revenue AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
  GROUP BY p.category
),
average_category AS (
  SELECT AVG(revenue) AS avg_revenue
  FROM category_revenue
)
SELECT ROUND(avg_revenue, 2) AS avg_revenue
FROM average_category;

-- 1: categories above the average category. (2 rows: Outerwear 76,637.00, Shoes 62,373.50)
-- @check 1
WITH category_revenue AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
  GROUP BY p.category
),
average_category AS (
  SELECT AVG(revenue) AS avg_revenue
  FROM category_revenue
)
SELECT category,
       ROUND(revenue, 2) AS revenue
FROM category_revenue
WHERE revenue > (SELECT avg_revenue FROM average_category)
ORDER BY revenue DESC;

-- 2, step 3: customers above the average customer (699.17). (91 rows)
-- @check 2, step 3
WITH customer_revenue AS (
  SELECT customer_id,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
),
average_customer AS (
  SELECT AVG(revenue) AS avg_revenue
  FROM customer_revenue
),
big_customers AS (
  SELECT customer_id, revenue
  FROM customer_revenue
  WHERE revenue > (SELECT avg_revenue FROM average_customer)
)
SELECT *
FROM big_customers
ORDER BY revenue DESC;

-- 2: how many, their revenue, and their share. (1 row: 91, 241,338.00, 76.4)
-- @check 2
WITH customer_revenue AS (
  SELECT customer_id,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
),
average_customer AS (
  SELECT AVG(revenue) AS avg_revenue
  FROM customer_revenue
),
big_customers AS (
  SELECT customer_id, revenue
  FROM customer_revenue
  WHERE revenue > (SELECT avg_revenue FROM average_customer)
)
SELECT COUNT(*) AS big_customers,
       ROUND(SUM(revenue), 2) AS their_revenue,
       ROUND(100 * SUM(revenue) / (SELECT SUM(revenue) FROM customer_revenue), 1) AS share_pct
FROM big_customers;

-- Bonus: the big customers by segment. (3 rows: retail 55, wholesale 35, unknown 1)
-- @check Bonus
WITH customer_revenue AS (
  SELECT customer_id,
         SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY customer_id
),
average_customer AS (
  SELECT AVG(revenue) AS avg_revenue
  FROM customer_revenue
),
big_customers AS (
  SELECT customer_id, revenue
  FROM customer_revenue
  WHERE revenue > (SELECT avg_revenue FROM average_customer)
)
SELECT COALESCE(LOWER(TRIM(c.segment)), 'unknown') AS segment_clean,
       COUNT(*) AS customers,
       ROUND(SUM(b.revenue), 2) AS revenue
FROM big_customers AS b
LEFT JOIN nakheel.customers AS c
  ON b.customer_id = c.customer_id
GROUP BY segment_clean
ORDER BY customers DESC;
