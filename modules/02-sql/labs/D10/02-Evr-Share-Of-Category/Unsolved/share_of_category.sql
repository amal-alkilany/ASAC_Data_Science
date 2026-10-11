-- D10 · 2.2 Everyone Do: Each product's share of its category
-- "What share of its category's revenue does each product bring?"

-- 1. Step 1: one row per product, completed revenue. Check it before you go on.
WITH product_revenue AS (

)
SELECT *
FROM product_revenue;

-- 2. Add the category total on every row: SUM(revenue) OVER (PARTITION BY category).


-- 3. Add the share, as a percentage with one decimal. Highest first.

