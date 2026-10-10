-- ============================================================
-- D03 Lab · Life expectancy · SOLVED
-- Table: owid.life_expectancy_data (Our World in Data, course copy of 24 Sep 2026)
-- ============================================================

-- ============================================================
-- C1  Is one row one place in one year? Check with Jordan in 2023.
-- One row is: one place (country, territory, region or group) in one year
-- Result check: 1 row, life_expectancy 77.8145
-- Interpretation: a baby born in Jordan in 2023 could expect about 78 years at that year's death rates.
-- ============================================================
-- @check C1
SELECT entity, code, year, life_expectancy
FROM owid.life_expectancy_data
WHERE entity = 'Jordan'
  AND year = 2023;

-- ============================================================
-- Q2  How has life expectancy in Jordan changed since 1950? Every year, oldest first.
-- One row is: Jordan in one year
-- Result check: 74 rows; 1950 is 40.8736, 2023 is 77.8145
-- Interpretation: Jordan gained about 37 years of life expectancy in 73 years.
-- ============================================================
-- @check Q2
SELECT year, life_expectancy
FROM owid.life_expectancy_data
WHERE entity = 'Jordan'
ORDER BY year;

-- ============================================================
-- Q3  Which ten places had the highest life expectancy in 2023?
-- One row is: one place in 2023
-- Result check: 10 rows; Monaco first (86.3724), Australia tenth (83.9228)
-- Interpretation: Hong Kong (third), Saint Barthelemy and French Polynesia are territories,
-- not countries. C3 shows why the list mixes them.
-- ============================================================
-- @check Q3
SELECT entity, code, life_expectancy
FROM owid.life_expectancy_data
WHERE year = 2023
ORDER BY life_expectancy DESC
LIMIT 10;

-- ============================================================
-- C3  "There are 193 UN member states. Why does 2023 have 261 rows?"
-- One row is: one place in 2023
-- Result check: 261, then 15, 246, 10 and 237 rows
-- Interpretation: 237 is still more than 193 because the list includes territories such as
-- Hong Kong, Greenland and Puerto Rico, which have their own statistics but are not UN members.
-- ============================================================
-- C3a All rows for 2023.
-- @check C3a
SELECT entity, code, life_expectancy
FROM owid.life_expectancy_data
WHERE year = 2023;

-- C3b Rows with no code: regions and groups such as Americas and Least developed countries.
-- @check C3b
SELECT entity, code
FROM owid.life_expectancy_data
WHERE year = 2023
  AND code IS NULL
ORDER BY entity;

-- C3c Remove them.
-- @check C3c
SELECT entity, code, life_expectancy
FROM owid.life_expectancy_data
WHERE year = 2023
  AND code IS NOT NULL;

-- C3d World is still there. Our World in Data gives its own regions codes starting OWID_.
-- @check C3d
SELECT entity, code
FROM owid.life_expectancy_data
WHERE year = 2023
  AND code LIKE 'OWID%'
ORDER BY entity;

-- C3e Countries and territories only, highest life expectancy first.
-- Kosovo also has an OWID_ code but is a country, so keep it.
-- @check C3e
SELECT entity, code, life_expectancy
FROM owid.life_expectancy_data
WHERE year = 2023
  AND code IS NOT NULL
  AND (code NOT LIKE 'OWID%' OR code = 'OWID_KOS')
ORDER BY life_expectancy DESC;

-- ============================================================
-- Stretch card: read the bytes estimate, do not run.
-- ============================================================
-- @skip public dataset; read the estimate only
SELECT *
FROM `bigquery-public-data.thelook_ecommerce.orders`;

-- @skip public dataset; read the estimate only
SELECT order_id, status
FROM `bigquery-public-data.thelook_ecommerce.orders`;

-- @skip public dataset; read the estimate only
SELECT *
FROM `bigquery-public-data.thelook_ecommerce.orders`
LIMIT 10;

-- ============================================================
-- More practice (not checked, not submitted)
-- ============================================================

-- P1 Life expectancy in 2023 for Jordan and its neighbours, highest first.
-- @check P1
SELECT entity, life_expectancy
FROM owid.life_expectancy_data
WHERE year = 2023
  AND entity IN ('Jordan', 'Egypt', 'Iraq', 'Lebanon', 'Palestine', 'Saudi Arabia', 'Syria')
ORDER BY life_expectancy DESC;

-- P2 Which countries had a life expectancy below 60 in 2023?
-- @check P2
SELECT entity, life_expectancy
FROM owid.life_expectancy_data
WHERE year = 2023
  AND life_expectancy < 60
  AND code IS NOT NULL
  AND code NOT LIKE 'OWID%'
ORDER BY life_expectancy;

-- P3 The ten countries with the lowest life expectancy in 1950.
-- @check P3
SELECT entity, life_expectancy
FROM owid.life_expectancy_data
WHERE year = 1950
  AND code IS NOT NULL
  AND code NOT LIKE 'OWID%'
ORDER BY life_expectancy
LIMIT 10;

-- P4 In which year did Japan first pass 80?
-- @check P4
SELECT year, life_expectancy
FROM owid.life_expectancy_data
WHERE entity = 'Japan'
  AND life_expectancy > 80
ORDER BY year
LIMIT 1;

-- P5 Which places have a name starting with "South"? Use 2023 only.
-- @check P5
SELECT entity, code
FROM owid.life_expectancy_data
WHERE year = 2023
  AND entity LIKE 'South%'
ORDER BY entity;

-- P6 Between 2015 and 2023, in which years was Jordan below 76?
-- @check P6
SELECT year, life_expectancy
FROM owid.life_expectancy_data
WHERE entity = 'Jordan'
  AND year BETWEEN 2015 AND 2023
  AND life_expectancy < 76
ORDER BY year;
