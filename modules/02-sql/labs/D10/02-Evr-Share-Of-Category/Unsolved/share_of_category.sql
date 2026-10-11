-- D10 · 2.2 Everyone Do: Each product's share of its category
-- "What share of its category's revenue does each product bring?"

-- 1. Step 1: one row per product, completed revenue: category, product_name, revenue. Check it before you go on.
WITH product_revenue AS (

)
SELECT *
FROM product_revenue;

-- 2. Keep category, product_name, revenue; add the category total on every row:
--    SUM(revenue) OVER (PARTITION BY category) AS category_revenue.


-- 3. Add the share, as a percentage rounded to 1 decimal, AS share_pct. Highest first: ORDER BY share_pct DESC.

