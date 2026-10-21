-- Assignment 1: Jordan on the world stage, in SQL
-- Name: AMAL OMAR MOHAMMAD ALKILANY
-- TA group: RAMI AIROUT
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
-- Answer: There are 49807 matches, 47914 goals, and 694 shootouts in the dataset, with matches spanning from November 30-1872, to September 30-2026.


-- Q2. The view football.team_matches: one row per team per match.
CREATE OR REPLACE VIEW football.team_matches AS
WITH both_sides AS (
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
select away_team as opponent,
home_team as team,
away_score as goals_against,
home_score as goals_for,
case
  when away_score > home_score then 'win'
  when away_score = home_score then 'draw'
  else 'loss'
end as result,
from football.matches;
)
SELECT

FROM both_sides;

-- Q2 audit: rows, different matches, wins, losses, draws.

;
-- Rows: 99614
-- Answer: 


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
-- Rows:1
-- Answer: Overall, Jordan has played 494 matches, achieving 181 wins,136 draws,and 177 losses. They scored 630 goals, conceded 559 goals, and have a win percentage of 36.6%.


-- Q4. Has Jordan got better over time? (by decade)
SELECT
DIV(EXTRACT(YEAR FROM match_date), 10) * 10 AS decade,
COUNT(*) AS matches,
ROUND(COUNTIF((home_team = 'Jordan' AND home_score > away_score) OR (away_team = 'Jordan' AND away_score > home_score)) / COUNT(*) * 100, 1) AS win_pct
FROM football.matches
WHERE home_team = 'Jordan' OR away_team = 'Jordan'
GROUP BY decade
ORDER BY decade ASC;
;
-- Rows: 7
-- Answer: yes, Jordan's win percentage has increased over the decades.


-- Q5. Opponents played at least 10 times.
select opponent,
count(*) as 	matches,
 countif(result = 'win') as wins,
 countif(result = 'draw') as draws,
 countif(result = 'loss') as losses
 from football.team_matches 
 where team = 'Jordan'
 group by opponent
 having matches >10
 order by matches desc, opponent desc;
;
-- Rows: 14
-- Answer: Iraq is the team Jordan played against the most with 48 matches.


-- Q6. Jordan's five biggest wins.

 select 
 match_date,
 away_team as opponent,
tournament,
 home_score as goals_for,
 away_score as goals_against,
 (home_score - away_score) as margin
 from football.matches
 where home_team = 'Jordan'
 order by margin DESC
 limit 5;
;
-- Rows: 5
-- Answer: Jordan's biggest win was 9-0 against Nepal in 2011.


-- =====================================================================
-- Part 3. Goals, scorers and what the data covers
-- =====================================================================

-- Q7. The 2023 Asian Cup, match by match, with a running total of Jordan's goals.
select match_date,
away_team as opponent,
home_score as goals_for,
away_score as goals_against,
case 
when home_score > away_score then 'win'
when home_score = away_score then 'draw'
else 'loss'
end as result,
sum(home_score) over (order by match_date ) as goals_so_far
from football.matches  
where home_team = 'Jordan'
order by match_date;

;
-- Rows:255
-- Answer: 0,0,2,2,3


-- Q8. Every goal of Jordan's first World Cup.
select m.match_date,
m.home_team,
m.away_team,
g.minute,
g.team,
g.scorer,
g.own_goal,
g.penalty
from football.matches as m 
inner join football.goals as g
      on m.match_id = g.match_id
where (m.home_team = 'Jordan' or m.away_team = 'Jordan') 
and m.tournament = 'FIFA World Cup'
and m.match_date between '2026-06-01' and '2026-07-31'
order by m.match_date asc, g.minute asc;
;
-- Rows: 11
-- Answer: No, because many scorer names are missing


-- Q9. Can we trust an all-time top scorers list from this data?
WITH t1 AS (
    SELECT DISTINCT match_id 
    FROM football.goals 
    WHERE team = 'Jordan'
),
t2 AS (
    SELECT match_id 
    FROM football.matches 
    WHERE (home_team = 'Jordan' AND home_score > 0)
       OR (away_team = 'Jordan' AND away_score > 0)
)
SELECT 
    COUNT(t2.match_id) AS scoring_matches,
    COUNTIF(t1.match_id IS NULL) AS no_scorer_recorded
FROM t2
LEFT JOIN t1 ON t2.match_id = t1.match_id;
;
-- Rows: 1
-- Answer: Jordan scored in 321 matches, but 240 matches have no scorer


-- =====================================================================
-- Part 4. The 2026 World Cup, step by step
-- =====================================================================

-- Q10. Teams with more goals per match than the average team.
WITH t1 AS (
  SELECT home_team AS team, home_score AS goals 
  FROM football.matches 
  WHERE tournament = 'FIFA World Cup' AND EXTRACT(YEAR FROM match_date) = 2026
  
  UNION ALL
  
  SELECT away_team AS team, away_score AS goals 
  FROM football.matches 
  WHERE tournament = 'FIFA World Cup' AND EXTRACT(YEAR FROM match_date) = 2026
),
t2 AS (
  SELECT 
    team,
    COUNT(*) AS matches,
    SUM(goals) AS goals,
    ROUND(SUM(goals) / COUNT(*), 2) AS goals_per_match
  FROM t1
  GROUP BY team
)
SELECT team, matches, goals, goals_per_match
FROM t2
WHERE goals_per_match > (SELECT AVG(goals_per_match) FROM t2)
ORDER BY goals_per_match DESC, team ASC;
;
-- Rows:22
-- Answer: Germany and Natherlands have the highest goals per match.


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

