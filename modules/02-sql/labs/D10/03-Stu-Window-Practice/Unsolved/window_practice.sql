-- D10 · 2.3 Student Do: Window practice: compare a row with its group
-- Before every query: what is one row, and what is the window?

-- 1. Each completed order next to the average order of its channel.
--    order_id, channel, order_total, channel_avg (rounded to 2 decimals). ORDER BY order_id.


-- 2. Customers above the average of their own segment, counted per segment.
--    Step 1, customer_revenue: customer_id, segment_clean, revenue
--    Step 2, with_segment_average: + segment_avg
--    Answer: segment_clean, customers_above_average. ORDER BY segment_clean.


-- 3. Each month's share of its year's revenue.
--    month, revenue, year_revenue, share_pct (rounded to 1 decimal). ORDER BY share_pct DESC.


-- Bonus: the biggest share among the months of 2025. ORDER BY share_pct DESC, LIMIT 1.

