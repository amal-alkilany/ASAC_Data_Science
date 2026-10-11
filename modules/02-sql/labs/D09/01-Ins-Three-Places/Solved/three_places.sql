-- D09 · 2.1 Instructor Do: Three places a subquery can live
-- The same inner query, "the average completed order", in WHERE, SELECT and FROM.

-- 1. The inner query on its own. (1 row: 114.05)
-- @check 1
SELECT AVG(order_total) AS average_order
FROM nakheel.orders
WHERE status = 'completed';

-- 2. In WHERE: one value to compare with. (689 rows; order 100849 first, 1,964.50)
-- @check 2
SELECT order_id, customer_id, order_total
FROM nakheel.orders
WHERE status = 'completed'
  AND order_total > (SELECT AVG(order_total)
                     FROM nakheel.orders
                     WHERE status = 'completed')
ORDER BY order_total DESC;

-- 3. In SELECT: exactly one value, repeated on every row. (2,771 rows; 100849 first, 1,850.45 above)
-- @check 3
SELECT order_id,
       order_total,
       ROUND((SELECT AVG(order_total)
              FROM nakheel.orders
              WHERE status = 'completed'), 2) AS average_order,
       ROUND(order_total - (SELECT AVG(order_total)
                            FROM nakheel.orders
                            WHERE status = 'completed'), 2) AS above_average_by
FROM nakheel.orders
WHERE status = 'completed'
ORDER BY above_average_by DESC;

-- 4a. The inner query for FROM, alone: one row per customer. (452 rows)
SELECT customer_id,
       SUM(order_total) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY customer_id;

-- 4b. In FROM: a table, named with AS. (1 row: 60)
-- @check 4
SELECT COUNT(*) AS customers_over_1000
FROM (SELECT customer_id,
             SUM(order_total) AS revenue
      FROM nakheel.orders
      WHERE status = 'completed'
      GROUP BY customer_id) AS per_customer
WHERE revenue > 1000;
