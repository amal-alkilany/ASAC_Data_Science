-- D07 · 3.3 Student Do: Category by segment, four tables

-- 1. Audit: completed order lines after all three joins. (1 row: 6,951 rows; 316,023.50)
-- @check 1
SELECT COUNT(*) AS row_count,
       ROUND(SUM(i.qty * i.price), 2) AS line_value
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id
INNER JOIN nakheel.orders AS o
  ON i.order_id = o.order_id
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed';

-- 2. Units and revenue for every category and cleaned segment. (16 rows: 6 categories x 2 segments,
-- plus 4 'unknown' rows from order 101664's lines. Outerwear, retail first: 1,403 units, 41,238.00)
-- @check 2
SELECT p.category,
       COALESCE(LOWER(TRIM(c.segment)), 'unknown') AS segment_clean,
       SUM(i.qty) AS units,
       ROUND(SUM(i.qty * i.price), 2) AS revenue
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id
INNER JOIN nakheel.orders AS o
  ON i.order_id = o.order_id
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY p.category, segment_clean
ORDER BY revenue DESC;

-- 3. Only the combinations worth more than 20,000. (10 rows; the last is Sportswear, wholesale, 20,580.50)
-- @check 3
SELECT p.category,
       COALESCE(LOWER(TRIM(c.segment)), 'unknown') AS segment_clean,
       SUM(i.qty) AS units,
       ROUND(SUM(i.qty * i.price), 2) AS revenue
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id
INNER JOIN nakheel.orders AS o
  ON i.order_id = o.order_id
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY p.category, segment_clean
HAVING SUM(i.qty * i.price) > 20000
ORDER BY revenue DESC;

-- Bonus (not checked). For each category, what share of completed revenue comes from wholesale?
-- The CASE inside SUM keeps a line's value only when the customer is wholesale, and 0 otherwise.
-- (6 rows: Shoes first, 53.5% wholesale; Accessories last, 45.2%)
-- @check Bonus
SELECT p.category,
       ROUND(SUM(CASE WHEN LOWER(TRIM(c.segment)) = 'wholesale' THEN i.qty * i.price ELSE 0 END), 2) AS wholesale_revenue,
       ROUND(SUM(i.qty * i.price), 2) AS revenue,
       ROUND(100 * SUM(CASE WHEN LOWER(TRIM(c.segment)) = 'wholesale' THEN i.qty * i.price ELSE 0 END)
             / SUM(i.qty * i.price), 1) AS wholesale_pct
FROM nakheel.order_items AS i
INNER JOIN nakheel.products AS p
  ON i.product_id = p.product_id
INNER JOIN nakheel.orders AS o
  ON i.order_id = o.order_id
LEFT JOIN nakheel.customers AS c
  ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY wholesale_pct DESC;
