-- D04 · 5.2 Instructor Do: "What does a typical order cost?"
-- Two grains, two honest answers. Say which one you mean.

-- Average value of one order LINE (one product on one order). Completed orders only.
-- The item table has no status, so the filter uses the list of completed order IDs.
SELECT ROUND(AVG(qty * price), 2) AS average_line_value,
       COUNT(*) AS lines
FROM nakheel.order_items
WHERE order_id IN (SELECT order_id FROM nakheel.orders WHERE status = 'completed');

-- Average value of one ORDER. Completed orders only.
SELECT ROUND(AVG(order_total), 2) AS average_order_value,
       COUNT(*) AS orders
FROM nakheel.orders
WHERE status = 'completed';

-- One more reason an average can mislead: a few very large wholesale orders pull it up.
-- Most orders are well under the average.
SELECT COUNTIF(order_total < 114.05) AS orders_below_average,
       COUNT(*) AS completed_orders
FROM nakheel.orders
WHERE status = 'completed';
