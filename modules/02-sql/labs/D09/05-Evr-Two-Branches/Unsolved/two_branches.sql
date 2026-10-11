-- D09 · 3.8 Everyone Do: Two branches, one answer
-- "Which categories grew most from our first year to our second?"
-- Year 1 = September 2024 to August 2025. Year 2 = September 2025 to August 2026. Completed orders.
-- The plan: two steps that do not need each other, then one step that joins them.
--   year_one : one row per category, revenue in year 1
--   year_two : one row per category, revenue in year 2
--   answer   : one row per category, both years side by side and the growth in percent

-- 1. Branch 1 alone. Finish the WHERE, run, and check the rows.
--    Then change the last SELECT to SELECT SUM(revenue) AS total FROM year_one and check the total.
WITH year_one AS (
  SELECT p.category,
         SUM(i.qty * i.price) AS revenue
  FROM nakheel.order_items AS i
  INNER JOIN nakheel.orders AS o
    ON i.order_id = o.order_id
  INNER JOIN nakheel.products AS p
    ON i.product_id = p.product_id
  WHERE o.status = 'completed'
    AND
  GROUP BY p.category
)
SELECT *
FROM year_one
ORDER BY revenue DESC;

-- 2. Branch 2: copy the whole CTE, rename it year_two and change only the two dates.
--    Check the rows and the total, as in 1.


-- 3. The answer: both CTEs in one WITH (a comma between them, none after the last),
--    then join them on category and work out the growth in percent. Highest growth first.


-- Bonus: growth in money as well as in percent. Largest growth in money first.

