-- D04 · 3.1 Everyone Do: check the four Nakheel tables in one query
-- UNION ALL stacks the results of several queries. You meet it properly later; for now, copy and run.
-- @check all
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM nakheel.customers
UNION ALL
SELECT 'products', COUNT(*) FROM nakheel.products
UNION ALL
SELECT 'orders', COUNT(*) FROM nakheel.orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM nakheel.order_items;
