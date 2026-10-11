-- D10 · 4.4 Everyone Do: One query that uses the whole module

-- 1. Step 1 alone. (451 rows)
-- @check 1
WITH customer_revenue AS (
  SELECT o.customer_id,
         c.customer_name,
         CASE
           WHEN c.city IS NULL THEN 'unknown'
           WHEN LOWER(TRIM(c.city)) = 'al zarqa' THEN 'zarqa'
           ELSE LOWER(TRIM(c.city))
         END AS city_clean,
         LOWER(TRIM(c.segment)) AS segment_clean,
         SUM(o.order_total) AS revenue
  FROM nakheel.orders AS o
  INNER JOIN nakheel.customers AS c
    ON o.customer_id = c.customer_id
  WHERE o.status = 'completed'
  GROUP BY o.customer_id, c.customer_name, city_clean, segment_clean
)
SELECT *
FROM customer_revenue
ORDER BY revenue DESC;

-- 4. The answer: the top three in each segment, with their share. (6 rows)
-- @check 4
WITH customer_revenue AS (
  SELECT o.customer_id,
         c.customer_name,
         CASE
           WHEN c.city IS NULL THEN 'unknown'
           WHEN LOWER(TRIM(c.city)) = 'al zarqa' THEN 'zarqa'
           ELSE LOWER(TRIM(c.city))
         END AS city_clean,
         LOWER(TRIM(c.segment)) AS segment_clean,
         SUM(o.order_total) AS revenue
  FROM nakheel.orders AS o
  INNER JOIN nakheel.customers AS c
    ON o.customer_id = c.customer_id
  WHERE o.status = 'completed'
  GROUP BY o.customer_id, c.customer_name, city_clean, segment_clean
),
ranked AS (
  SELECT customer_id,
         customer_name,
         city_clean,
         segment_clean,
         revenue,
         RANK() OVER (PARTITION BY segment_clean ORDER BY revenue DESC) AS segment_rank,
         ROUND(100 * revenue / SUM(revenue) OVER (PARTITION BY segment_clean), 1) AS share_of_segment
  FROM customer_revenue
)
SELECT segment_clean,
       segment_rank,
       customer_id,
       customer_name,
       city_clean,
       revenue,
       share_of_segment
FROM ranked
WHERE segment_rank <= 3
ORDER BY segment_clean, segment_rank;
