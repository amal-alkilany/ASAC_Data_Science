-- D08 · 3.2 Everyone Do: A two-step pipeline
-- "Which months were better than our average month?"
-- Plan the steps before you type:
--   (1)
--   (2)
--   (3)

-- 1. Step 1 alone: completed revenue per month. Check it before you go on.
WITH monthly AS (

)
SELECT *
FROM monthly
ORDER BY month;

-- 2. Steps 1 and 2: add a second CTE, average_month, that reads monthly. One row: the average month.


-- 3. The answer: the months above the average, using average_month as a one-number subquery.

