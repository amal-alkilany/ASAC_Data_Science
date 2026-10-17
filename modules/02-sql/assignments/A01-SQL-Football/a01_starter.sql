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
select
(select count(*) from football.matches) as matches,
(select count(*) from football.goals) as goals,
(select count(*) from football.shootouts) as shootouts,
(select min(match_date)from football.matches) as first_match,
(select max(match_date) from football.matches) as last_match;
;
-- Rows: 1
-- Answer: there are 49807 matches, 47914 goals, and 694 shootouts in the dataset, with matches spanning from November 30.1872, to September 30.2026.


-- Q2. The view football.team_matches: one row per team per match.
CREATE OR REPLACE VIEW football.team_matches AS
select home_team as team,
away_team as opponent,
home_score as goals_for,
away_score as goals_against,
case
  when home_score > away_score then 'win'
  when home_score = away_score then 'draw'
  else 'loss'
end as result,
from football.matches
union all
select away_team as team,
home_team as opponent,
away_score as goals_against,
home_score as goals_for,
case
  when away_score > home_score then 'win'
  when away_score = home_score then 'draw'
  else 'loss'
end as result,
from football.matches;

)
SELECT *

FROM both_sides;
WITH both_sides AS (


-- Q2 audit: rows, different matches, wins, losses, draws.

;
-- Rows: 99614
-- Answer: win must equal losses because for every match where one team wins, the opposing team must lose.


-- =====================================================================
-- Part 2. Jordan in numbers
-- =====================================================================

-- Q3. How has Jordan done overall?
select 
 count(*) as 	total_matches,
 countif(result = 'win') as wins,
 countif(result = 'draw') as draws,
 countif(result = 'loss') as losses,
 sum(goals_for) as goals_for,
 sum(goals_against) as goals_against,
 round(countif(result = 'win')/count(*) * 100,1) as win_pct
from football.team_matches 
where team = 'Jordan';
;
-- Rows: 1
-- Answer: Overall, Jordan has played 494 matches, achieving 181 wins, 136 draws, and 177 losses. They scored 630 goals, conceded 559 goals, and have a win percentage of 36.6%.
   


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


-- =====================================================================
-- Bonus (not graded)
-- =====================================================================

-- B1. The Golden Boot race: the top three places.

;
-- Rows:
-- Answer:


-- B2. Jordan's goals per year since 2015: change on the year before, and running total.

;
-- Rows:
-- Answer:


-- B3. Penalty shootouts.

;
-- Rows:
-- Answer:

