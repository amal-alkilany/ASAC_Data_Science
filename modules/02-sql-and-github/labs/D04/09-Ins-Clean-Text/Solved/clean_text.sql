-- D04 · 4.3 Instructor Do: fix the D01 problem in one line

-- As typed: five spellings of two segments. (5 rows)
SELECT segment, COUNT(*) AS customers
FROM nakheel.customers
GROUP BY segment
ORDER BY segment;

-- TRIM removes spaces at the ends; LOWER makes every letter small. (2 rows)
SELECT LOWER(TRIM(segment)) AS segment_clean,
       COUNT(*) AS customers
FROM nakheel.customers
GROUP BY segment_clean
ORDER BY customers DESC;

-- COALESCE replaces NULL with a value you choose, here for display. (10 rows)
-- TRIM and LOWER fix "amman". They cannot know that "Al Zarqa" is Zarqa: that needs a rule
-- you write yourself, as a CASE, or a cleaning step in Power Query (Module 3).
SELECT COALESCE(LOWER(TRIM(city)), 'unknown') AS city_clean,
       COUNT(*) AS customers
FROM nakheel.customers
GROUP BY city_clean
ORDER BY customers DESC;
