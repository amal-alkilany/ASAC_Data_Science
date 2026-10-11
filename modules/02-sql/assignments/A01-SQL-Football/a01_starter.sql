-- Assignment 1: Jordan on the world stage, in SQL
-- Name:
-- TA group:
--
-- Save this file as A01_<FirstName>_<LastName>.sql.
-- Under every query: the number of rows it returned, and one sentence that answers the question.
-- The file must run from top to bottom without errors: the view in Q2 has to exist before Q3 reads it.


-- =====================================================================
-- Part 1. Load and check the data
-- =====================================================================

-- Q1. Row counts of the three tables, and the first and last match_date, in one row.

;
-- Rows:
-- Answer:


-- Q2. The view football.team_matches: one row per team per match.
CREATE OR REPLACE VIEW football.team_matches AS
WITH both_sides AS (

)
SELECT

FROM both_sides;

-- Q2 audit: rows, different matches, wins, losses, draws.

;
-- Rows:
-- Answer:


-- =====================================================================
-- Part 2. Jordan in numbers
-- =====================================================================

-- Q3. How has Jordan done overall?

;
-- Rows:
-- Answer:


-- Q4. Has Jordan got better over time? (by decade)

;
-- Rows:
-- Answer:


-- Q5. Opponents played at least 10 times.

;
-- Rows:
-- Answer:


-- Q6. Jordan's five biggest wins.

;
-- Rows:
-- Answer:


-- =====================================================================
-- Part 3. Goals, scorers and what the data covers
-- =====================================================================

-- Q7. The 2023 Asian Cup, match by match, with a running total of Jordan's goals.

;
-- Rows:
-- Answer:


-- Q8. Every goal of Jordan's first World Cup.

;
-- Rows:
-- Answer:


-- Q9. Can we trust an all-time top scorers list from this data?

;
-- Rows:
-- Answer:


-- =====================================================================
-- Part 4. The 2026 World Cup, step by step
-- =====================================================================

-- Q10. Teams with more goals per match than the average team.

;
-- Rows:
-- Answer:


-- Q11. The Golden Boot race: the top three places.

;
-- Rows:
-- Answer:


-- Q12. Jordan's goals per year since 2015: change on the year before, and running total.

;
-- Rows:
-- Answer:


-- Bonus (not graded). Penalty shootouts.

