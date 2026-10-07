-- D06 · 4.2 Everyone Do: D01's answer, in SQL
-- It is September 2026, the setting of D01:
-- "Which product category produced the most completed-order revenue last month?"
-- Last month is August 2026.
--
-- Audit table
-- | Step                        | Rows | SUM(qty * price) |
-- |-----------------------------|------|------------------|
-- | order_items alone           |      |                  |
-- | + orders                    |      |                  |
-- | + products                  |      |                  |

-- 1. order_items alone


-- 2. + orders


-- 3. + products


-- 4. The answer: completed orders placed in August 2026, grouped by category.
--    Write "last month" as dates: o.order_date BETWEEN '2026-08-01' AND '2026-08-31'


-- 5. The same without the status filter. Keep the orders join and the date filter.

