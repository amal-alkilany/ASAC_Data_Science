-- D08 · 4.1 Instructor Do: Save a query as a view
-- A view is a saved query with a name. It stores no rows: every time you read it, BigQuery runs the query again.
-- Create the dataset `bi` first, in the console: Create dataset, ID `bi`, the same location as `nakheel` (Multi-region US).

-- One row per order line, with what Power BI will need from the order. No ORDER BY inside a view.
-- Creates the view; the next query checks it.
CREATE OR REPLACE VIEW bi.fact_sales AS
SELECT i.item_id,
       i.order_id,
       o.order_date,
       o.channel,
       o.status,
       o.customer_id,
       i.product_id,
       i.qty,
       i.price,
       i.qty * i.price AS revenue
FROM nakheel.order_items AS i
INNER JOIN nakheel.orders AS o
  ON i.order_id = o.order_id;

-- Step 4. Read it like a table: the audit. (1 row: 7,516 lines; 3,000 orders; 340,370.00; completed 316,023.50)
-- @check 4
SELECT COUNT(*) AS line_rows,
       COUNT(DISTINCT order_id) AS different_orders,
       ROUND(SUM(revenue), 2) AS all_revenue,
       ROUND(SUM(CASE WHEN status = 'completed' THEN revenue END), 2) AS completed_revenue
FROM bi.fact_sales;
