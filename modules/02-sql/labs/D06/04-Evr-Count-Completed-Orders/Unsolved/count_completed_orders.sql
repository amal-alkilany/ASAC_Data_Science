-- D06 · 3.1 Everyone Do: "How many completed orders?"

-- 1. Count completed orders on D03.orders.


-- 2. Join D03.order_items to D03.orders and count the rows again, completed only.


-- 3. Change the count so it answers the question.



-- 4. "How many completed orders included at least one item priced 20 or more?"
--    "Priced" means the unit price, not qty * price.
--    4a: write it with COUNT(*). 4b: write it with COUNT(DISTINCT o.order_id).

