-- D06 · 4.1 Instructor Do: Sum each amount where it lives

-- 1. Wrong: order_total is an order-level amount, copied onto every line of the order. (2 rows)
-- @check 1
SELECT o.channel,
       ROUND(SUM(o.order_total), 2) AS revenue_inflated
FROM nakheel.orders AS o
INNER JOIN nakheel.order_items AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed'
GROUP BY o.channel
ORDER BY o.channel;

-- 2. Fix 1: sum the amount that lives at the line grain. (2 rows)
-- @check 2
SELECT o.channel,
       ROUND(SUM(i.qty * i.price), 2) AS revenue
FROM nakheel.orders AS o
INNER JOIN nakheel.order_items AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed'
GROUP BY o.channel
ORDER BY o.channel;

-- 3. Fix 2: an order-level amount needs no join at all. (2 rows)
-- @check 3
SELECT channel,
       ROUND(SUM(order_total), 2) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY channel
ORDER BY channel;

-- 4. Counting orders after the join: count distinct orders, not rows. (2 rows)
-- @check 4
SELECT o.channel,
       COUNT(*) AS rows_after_join,
       COUNT(DISTINCT o.order_id) AS completed_orders
FROM nakheel.orders AS o
INNER JOIN nakheel.order_items AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed'
GROUP BY o.channel
ORDER BY o.channel;

-- 5a. shipping_fee also lives on orders, so it inflates in exactly the same way. (1 row)
-- @check 5a
SELECT ROUND(SUM(o.shipping_fee), 2) AS shipping_after_join
FROM nakheel.orders AS o
INNER JOIN nakheel.order_items AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed';

-- 5b. The true figure: shipping_fee summed on orders alone, with no join. (1 row)
-- @check 5b
SELECT ROUND(SUM(shipping_fee), 2) AS shipping_on_orders
FROM nakheel.orders
WHERE status = 'completed';
