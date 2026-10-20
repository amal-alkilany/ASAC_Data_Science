-- D15 · A monthly series: load it and look at it · Solved (every query from the README, in order)
-- Run one statement at a time, in order. CREATE MODEL and the ML. functions run in BigQuery only.

-- Step 1 · How many months, from when to when
SELECT COUNT(*) AS months, MIN(month) AS first_month, MAX(month) AS last_month
FROM ml.air_passengers;

-- Step 2 · No month missing, none twice
SELECT DATE_DIFF(MAX(month), MIN(month), MONTH) + 1 AS months_in_range,
       COUNT(DISTINCT month) AS distinct_months
FROM ml.air_passengers;

-- Step 3 · The trend: one row per year
SELECT EXTRACT(YEAR FROM month) AS year_number, SUM(passengers) AS yearly_total
FROM ml.air_passengers
GROUP BY year_number
ORDER BY year_number;

-- Step 4 · The season: the same shape every year
SELECT EXTRACT(MONTH FROM month) AS month_of_year,
       ROUND(AVG(passengers), 1) AS average_passengers
FROM ml.air_passengers
WHERE month < '1959-01-01'
GROUP BY month_of_year
ORDER BY month_of_year;

-- Step 5 · Does the season grow?
SELECT EXTRACT(YEAR FROM month) AS year_number,
       MIN(passengers) AS quietest_month,
       MAX(passengers) AS busiest_month,
       MAX(passengers) - MIN(passengers) AS swing
FROM ml.air_passengers
WHERE month < '1959-01-01'
GROUP BY year_number
ORDER BY year_number;
