# Assignment 1: Jordan on the world stage, in SQL

In this assignment, you will load 150 years of international football results into BigQuery and answer twelve questions about Jordan and the 2026 World Cup, using the SQL from D03 to D10.

**Weight:** 20% of the course grade · **Issued:** D10, Monday 12 October 2026 · **Due:** before **4:00 PM on D13, Wednesday 21 October 2026**

**Data:** [International football results](../../../../shared/datasets/intl_football/README.md), three CSV files you upload as `football.matches`, `football.goals` and `football.shootouts` · **Starter:** [`a01_starter.sql`](a01_starter.sql)

## The scenario

The Jordan Football Association's new analytics team is preparing a report for the 2026–27 season. Jordan played its first World Cup in June 2026, two years after reaching the final of the AFC Asian Cup. The team has the full match history but nobody who writes SQL. You do.

Every answer goes in one `.sql` file. Under each query, write the number of rows it returned and one sentence that answers the question the way you would say it to the head of the analytics team.

## What to submit

One file named `A01_<FirstName>_<LastName>.sql`, built from the starter. For each question:

```sql
-- Q3. How has Jordan done overall?
SELECT ...
;
-- Rows: 1
-- Answer: Jordan has won ... of its ... matches ...
```

Submit it through the link your TA shares in your group channel, before 4:00 PM on Wednesday 21 October.

**Help:** the optional support session on **Tuesday 20 October, 4:00–6:00 PM**, is for Assignment 1 questions. Your TA can help you read an error message; they will not write a query for you.

## Part 1. Load and check the data

1. **Upload the three files** into a new dataset, `football`, following [the dataset README](../../../../shared/datasets/intl_football/README.md). Then write **one query** that returns, in a single row, the number of rows in each table and the first and last `match_date`.

    Translate: three counts and two dates from different tables in one row. A subquery in `SELECT` returns one value, so five of them make one row (D09).

2. **One row per team per match.** A match has two teams, so most team questions need to read `home_team` and `away_team` both. Build that once, as a view: `football.team_matches`, with one row per team per match.

    Translate: one `SELECT` for the home side (`home_team AS team`, `away_team AS opponent`, `home_score AS goals_for`, `away_score AS goals_against`) and one for the away side, the other way round, stacked with `UNION ALL` (D07). Keep `match_id`, `match_date` and `tournament`. Put the stack in a CTE and add a `result` column, `'win'`, `'draw'` or `'loss'`, with `CASE` (D04). Save it with `CREATE OR REPLACE VIEW` (D09).

    Then audit the view: its rows, its different `match_id` values, and the number of wins, losses and draws.

### Check yourself (Part 1 only)

| Question | Rows returned | One value to check |
|---|---:|---|
| 1 | 1 | 49,807 matches · 47,914 goals · 694 shootouts · 1872-11-30 · 2026-09-30 |
| 2, the audit | 1 | 99,614 rows, 49,807 matches; wins and losses are equal |

Why must wins equal losses? Every match that one team wins, another team loses. If your counts differ, check the order of the columns in your two `SELECT`s. `UNION ALL` matches columns by position, not by name.

The rest of the assignment has no Check yourself: the numbers are what is graded. Use `football.team_matches` wherever a question is about a team.

## Part 2. Jordan in numbers

3. **"How has Jordan done overall?"** Matches played, wins, draws, losses, goals scored, goals conceded, and the win rate as a percentage with one decimal.

    Translate: one row. `COUNTIF` counts the rows where a test is true (D08).

4. **"Has Jordan got better over time?"** The same win rate for each decade, oldest first, with the number of matches in each.

    Translate: `DIV(EXTRACT(YEAR FROM match_date), 10) * 10` turns 2024 into 2020: the decade. `DIV` is integer division, a BigQuery function.

5. **"Who do we play most, and how do we do against them?"** Every opponent Jordan has played at least 10 times, with matches, wins, draws and losses. Most-played first; opponents played the same number of times in alphabetical order.

6. **"What are our five biggest wins?"** Date, opponent, tournament, the score and the winning margin. When two wins have the same margin, the earlier comes first.

## Part 3. Goals, scorers and what the data covers

7. **"Take me through the 2023 Asian Cup."** Jordan's matches at the AFC Asian Cup 2023, in order, with the opponent, the score, the result, and how many goals Jordan had scored in the tournament after each match.

    Translate: the tournament was played from 12 January to 10 February 2024 (see the dataset README). The last column is a running total, `SUM(...) OVER (ORDER BY ...)` (D10).

8. **"Every goal of Jordan's first World Cup."** For each goal in Jordan's three matches at the 2026 World Cup, by either team: the match date, the two teams, the minute, the team it counted for, the scorer, and whether it was an own goal or a penalty. In match order, then minute order.

    Translate: `matches` joined to `goals` (D06). The 2026 World Cup is `tournament = 'FIFA World Cup'` between 1 June and 31 July 2026.

9. **"Can we trust an all-time top scorers list from this data?"** Before anyone builds one: in how many of Jordan's matches did Jordan score at least one goal, and in how many of those does `goals` have no Jordan scorer at all? Answer the question in your comment.

    Translate: a list of the `match_id` values that have a Jordan goal in `goals`, in a CTE; Jordan's scoring matches from `team_matches`, `LEFT JOIN` that list, and count the rows where it found nothing (D07).

## Part 4. The 2026 World Cup, step by step

10. **"Which teams scored more goals per match than the average team?"** For every team at the 2026 World Cup: matches, goals and goals per match (two decimals). Keep only the teams above the average of all teams' goals per match. Best first; teams with the same rate in alphabetical order.

    Translate: step 1, a CTE with one row per team. Step 2, the average of that step's goals per match, as a subquery in `WHERE` (D09).

11. **"Who won the Golden Boot race?"** The top three places among the 2026 World Cup scorers, by goals, not counting own goals. Players with the same number of goals share a place, and the next place is not skipped.

    Translate: one row per scorer and team in a CTE; then a ranking function, the one that does not skip a number after a tie (D10). `QUALIFY` keeps the ranks you want.

12. **"Is Jordan scoring more than it used to?"** For each year from 2015: Jordan's matches, goals scored, the change in goals on the year before, and the running total of goals since 2015.

    Translate: one row per year in a CTE, then `LAG` and a running total (D10). Look at 2020 before you write your sentence.

## Bonus (not graded)

Jordan has gone to a penalty shootout five times. How many did it win? Which team has won the most shootouts of all time?

## How it is graded

| Criterion | Weight | Full marks when |
|---|---:|---|
| Correct results | 40% | Each query returns the right rows and values for its question (Part 1: 2 points each; questions 3–12: 3.6 points each) |
| Row counts | 20% | Every answer states its row count, and the Part 1 audits are there and agree with the data |
| The answer in words | 20% | Every answer has one sentence a non-technical manager could act on, with the number that supports it; question 9 says what the data can and cannot tell us |
| Readable SQL | 20% | CTEs and columns have names that say what one row is; aliases on every joined table; one clause per line; the file runs from top to bottom without errors |

A query that runs but answers a different question gets no marks for correctness, so reread each question before you move on. A query that has an error gets no marks for correctness but can still earn the other three.

## References

Mart Jürisoo, [International football results from 1872 to 2026](https://github.com/martj42/international_results), CC0 1.0. Course copy taken 9 October 2026 (matches to 30 September 2026); see [the dataset README](../../../../shared/datasets/intl_football/README.md) for what was changed.
