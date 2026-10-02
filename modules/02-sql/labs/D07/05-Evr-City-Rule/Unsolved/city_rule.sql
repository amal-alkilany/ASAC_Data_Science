-- D07 · 3.2 Everyone Do: A cleaning rule of your own
-- "Completed revenue by city." The city is on customers; the amount is on orders.

-- 1. Completed orders by city, as typed: orders LEFT JOIN customers, grouped by c.city.
--    Nakheel has 8 cities. How many rows do you expect?


-- 2. Write the rule in words first:
--    no city at all      -> 'unknown'
--    Al Zarqa            -> 'zarqa'
--    everything else     -> trimmed and lower-case
--    Then write it as a CASE called city_clean, and report completed orders and revenue by city_clean.

