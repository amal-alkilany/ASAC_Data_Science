-- D10 · 6.2 Everyone Do: Load the Assignment 1 data
-- The football tables are checked in instructor/w02/a01 (DuckDB on the course copy).

-- @skip
SELECT COUNT(*) AS matches
FROM football.matches;

-- @skip
SELECT COUNT(*) AS goals
FROM football.goals;

-- @skip
SELECT COUNT(*) AS shootouts
FROM football.shootouts;
