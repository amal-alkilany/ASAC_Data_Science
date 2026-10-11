-- D10 · 4.3 Student Do: Window practice: rank and trend
-- Before every query: what is one row, what is the window, and in what order does it count?

-- 1. The three biggest completed orders in each channel.
--    channel, order_id, order_total, place. ORDER BY channel, place.


-- 2. Each channel's monthly revenue and its change on that channel's previous month.
--    channel, month, revenue, change. Then: the biggest one-month jump, ORDER BY change DESC.


-- 3. Our three best months, with their rank: month, revenue, month_rank. ORDER BY month_rank.


-- Bonus: a running total for each channel, AS running_total. ORDER BY channel, month.

