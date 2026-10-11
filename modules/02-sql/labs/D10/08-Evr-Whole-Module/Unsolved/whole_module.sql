-- D10 · 4.5 Everyone Do: One query that uses the whole module
-- "For each segment, who are our three biggest customers, which city are they in,
--  and what share of the segment's completed revenue does each one bring?"
-- Plan:
--   Step 1, customer_revenue:
--   Step 2, ranked:
--   Answer: (segment_clean, segment_rank, customer_id, customer_name, city_clean, revenue,
--            share_of_segment; ORDER BY segment_clean, segment_rank)

WITH customer_revenue AS (

)
SELECT *
FROM customer_revenue;
