# Assignment 1: Jordan on the world stage, in SQL

In this assignment, you will load 150 years of international football results into BigQuery and answer ten questions about Jordan and the 2026 World Cup, with three bonus questions if you want more, using the SQL from D03 to D10.

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

**One question, one query.** Each question is answered by one final query, and its **Your result** table is what that query returns. Question 2 is the only exception: the `CREATE OR REPLACE VIEW` statement, then one audit query. Some hints ask you to run part of a query on its own first. That is a check for you, not part of the answer: leave it out of your file, or keep it as a comment.

Submit it through the link your TA shares in your group channel, before 4:00 PM on Wednesday 21 October.

**Help:** the optional support session on **Tuesday 20 October, 4:00–6:00 PM**, is for Assignment 1 questions. Your TA can help you read an error message; they will not write a query for you.

## Part 1. Load and check the data

1. **Upload the three files** into a new dataset, `football`, following [the dataset README](../../../../shared/datasets/intl_football/README.md). Then write **one query** that returns, in a single row, the number of rows in each table and the first and last `match_date`.

    Translate: three counts and two dates from different tables in one row. A subquery in `SELECT` returns one value, so five of them make one row (D09). The outer `SELECT` needs no `FROM`.

    **Your result:** 1 row:

    | Row | matches | goals | shootouts | first_match | last_match |
    |---:|---|---|---|---|---|
    | 1 | 49807 | 47914 | 694 | 1872-11-30 | 2026-09-30 |

2. **One row per team per match.** A match has two teams, so most team questions need to read `home_team` and `away_team` both. Build that once, as a view: `football.team_matches`, with one row per team per match.

    Translate: one `SELECT` for the home side (`home_team AS team`, `away_team AS opponent`, `home_score AS goals_for`, `away_score AS goals_against`) and one for the away side, the other way round, stacked with `UNION ALL` (D07). Keep `match_id`, `match_date` and `tournament`. Put the stack in a CTE and add a `result` column, `'win'`, `'draw'` or `'loss'`, with `CASE` (D04). Save it with `CREATE OR REPLACE VIEW` (D09).

    > **Hint:** before you save the view, run the CTE on its own with `WHERE match_id = 1`. You should see two rows, Scotland and England, each with the other as its opponent. If a team is its own opponent, a column is in the wrong place. This is a check only: your file keeps the view and the audit.

    Then audit the view: its rows, its different `match_id` values, and the number of wins, losses and draws. The audit reads the view, `football.team_matches`, not `matches`: `result` only exists in the view.

    **Your result** of the audit query: 1 row:

    | Row | team_rows | different_matches | wins | losses | draws |
    |---:|---|---|---|---|---|
    | 1 | 99614 | 49807 | 38498 | 38498 | 22618 |

Why must wins equal losses? Every match that one team wins, another team loses. If your counts differ, check the order of the columns in your two `SELECT`s. `UNION ALL` matches columns by position, not by name.

Every question shows **its result**: how many rows it returns and, at most, its first five rows, as BigQuery shows them. Use it to check your query before you move on. Your column names may be different; the values and the order should not be. Matching the result is not the whole job: the marks also go to your row counts, your sentences and readable SQL.

Use `football.team_matches` wherever a question is about a team.

## Part 2. Jordan in numbers

3. **"How has Jordan done overall?"** Matches played, wins, draws, losses, goals scored, goals conceded, and the win rate as a percentage with one decimal.

    Translate: one row. `COUNTIF` counts the rows where a test is true (D04).

    **Your result:** 1 row:

    | Row | matches | wins | draws | losses | goals_for | goals_against | win_pct |
    |---:|---|---|---|---|---|---|---|
    | 1 | 494 | 181 | 136 | 177 | 630 | 559 | 36.6 |


4. **"Has Jordan got better over time?"** The same win rate for each decade, oldest first, with the number of matches in each.

    Translate: `DIV(EXTRACT(YEAR FROM match_date), 10) * 10` turns 2024 into 2020: the decade. `DIV` is integer division, a BigQuery function. The 2020s are not over yet (the data stops on 30 September 2026), so say so if you compare them with earlier decades.

    **Your result:** 7 rows. The first 5:

    | Row | decade | matches | win_pct |
    |---:|---|---|---|
    | 1 | 1960 | 13 | 7.7 |
    | 2 | 1970 | 7 | 28.6 |
    | 3 | 1980 | 38 | 26.3 |
    | 4 | 1990 | 45 | 35.6 |
    | 5 | 2000 | 148 | 36.5 |


5. **"Who do we play most, and how do we do against them?"** Every opponent Jordan has played at least 10 times, with matches, wins, draws and losses. Most-played first; opponents played the same number of times in alphabetical order.

    > **Hint:** "at least 10 times" is a rule about a group of matches, not about one row. Which clause filters groups after `GROUP BY`?

    **Your result:** 14 rows. The first 5:

    | Row | opponent | matches | wins | draws | losses |
    |---:|---|---|---|---|---|
    | 1 | Iraq | 48 | 10 | 13 | 25 |
    | 2 | Syria | 30 | 11 | 11 | 8 |
    | 3 | Bahrain | 26 | 12 | 5 | 9 |
    | 4 | Kuwait | 26 | 6 | 11 | 9 |
    | 5 | Lebanon | 26 | 8 | 12 | 6 |

6. **"What are our five biggest wins?"** Date, opponent, tournament, the score and the winning margin. When two wins have the same margin, the earlier comes first.

    > **Hint:** biggest means the widest margin, not the most goals. A 6-1 win has more goals than a 6-0 win, but it is the smaller win.

    **Your result:** 5 rows:

    | Row | match_date | opponent | tournament | goals_for | goals_against | margin |
    |---:|---|---|---|---|---|---|
    | 1 | 2011-07-23 | Nepal | FIFA World Cup qualification | 9 | 0 | 9 |
    | 2 | 2016-03-24 | Bangladesh | FIFA World Cup qualification | 8 | 0 | 8 |
    | 3 | 2017-03-28 | Cambodia | AFC Asian Cup qualification | 7 | 0 | 7 |
    | 4 | 2024-03-26 | Pakistan | FIFA World Cup qualification | 7 | 0 | 7 |
    | 5 | 2001-05-03 | Taiwan | FIFA World Cup qualification | 6 | 0 | 6 |

## Part 3. Goals, scorers and what the data covers

7. **"Take me through the 2023 Asian Cup."** Jordan's matches at the AFC Asian Cup 2023, in order, with the opponent, the score, the result, and how many goals Jordan had scored in the tournament after each match.

    Translate: the tournament was played from 12 January to 10 February 2024 (see the dataset README). The last column is a running total, `SUM(...) OVER (ORDER BY ...)` (D10).

    > **Hint:** write the query without the running total first and check that you get Jordan's seven matches. Then add the column. Ask yourself in what order the goals should add up.

    **Your result:** 7 rows. The first 5:

    | Row | match_date | opponent | goals_for | goals_against | result | goals_so_far |
    |---:|---|---|---|---|---|---|
    | 1 | 2024-01-15 | Malaysia | 4 | 0 | win | 4 |
    | 2 | 2024-01-20 | South Korea | 2 | 2 | draw | 6 |
    | 3 | 2024-01-25 | Bahrain | 0 | 1 | loss | 6 |
    | 4 | 2024-01-29 | Iraq | 3 | 2 | win | 9 |
    | 5 | 2024-02-02 | Tajikistan | 1 | 0 | win | 10 |


8. **"Every goal of Jordan's first World Cup."** For each goal in Jordan's three matches at the 2026 World Cup, by either team: the match date, the two teams, the minute, the team it counted for, the scorer, and whether it was an own goal or a penalty. In match order, then minute order.

    Translate: `matches` joined to `goals` (D06). The 2026 World Cup is `tournament = 'FIFA World Cup'` between 1 June and 31 July 2026.

    > **Hint:** your `WHERE` mixes `AND` and `OR`. `AND` is applied first, so what happens to the `OR` part without brackets? If you get far more than 11 rows, look there.

    **Your result:** 11 rows. The first 5:

    | Row | match_date | home_team | away_team | minute | team | scorer | own_goal | penalty |
    |---:|---|---|---|---|---|---|---|---|
    | 1 | 2026-06-16 | Austria | Jordan | 20 | Austria | Romano Schmid | false | false |
    | 2 | 2026-06-16 | Austria | Jordan | 50 | Jordan | Ali Olwan | false | false |
    | 3 | 2026-06-16 | Austria | Jordan | 76 | Austria | Yazan Al-Arab | true | false |
    | 4 | 2026-06-16 | Austria | Jordan | 90 | Austria | Marko Arnautović | false | true |
    | 5 | 2026-06-22 | Jordan | Algeria | 36 | Jordan | Nizar Al-Rashdan | false | false |

9. **"Can we trust an all-time top scorers list from this data?"** Before anyone builds one: in how many of Jordan's matches did Jordan score at least one goal, and in how many of those does `goals` have no Jordan scorer at all? Answer the question in your comment.

    Translate: a list of the `match_id` values that have a Jordan goal in `goals`, in a CTE; Jordan's scoring matches from `team_matches`, `LEFT JOIN` that list, and count the rows where it found nothing (D07).

    > **Hint:** think of two lists of matches: the ones where Jordan scored (from the score), and the ones where `goals` names a Jordan scorer. You want the matches in the first list that are missing from the second. After a `LEFT JOIN`, what does a row that found no partner hold in the right-hand table's columns?

    **Your result:** 1 row:

    | Row | scoring_matches | no_scorer_recorded |
    |---:|---|---|
    | 1 | 321 | 240 |


## Part 4. The 2026 World Cup, step by step

10. **"Which teams scored more goals per match than the average team?"** For every team at the 2026 World Cup: matches, goals and goals per match (two decimals). Keep only the teams above the average of the 48 teams' goals-per-match figures. Best first; teams with the same rate in alphabetical order.

    Translate: step 1, a CTE with one row per team. Step 2, the average of that step's goals per match, as a subquery in `WHERE` (D09).

    > **Hint:** build it in steps. Run step 1 on its own: 48 rows, one per team. Then run `SELECT AVG(...)` on step 1 on its own and write the number down. Only then put it inside `WHERE`. Your answer is the one final query; the two checks stay out of your file.

    **Your result:** 22 rows. The first 5:

    | Row | team | matches | goals | goals_per_match |
    |---:|---|---|---|---|
    | 1 | Germany | 4 | 11 | 2.75 |
    | 2 | Netherlands | 4 | 11 | 2.75 |
    | 3 | England | 8 | 20 | 2.5 |
    | 4 | France | 8 | 20 | 2.5 |
    | 5 | Senegal | 4 | 10 | 2.5 |


## Bonus (not graded)

These use the window functions from D10. They are not graded, but they are the best practice you will get before Assignment 2 and Power BI. Put them at the end of your file, under the bonus heading in the starter.

- **B1. "Who won the Golden Boot race?"** The top three places among the 2026 World Cup scorers, by goals, not counting own goals. Players with the same number of goals share a place, and the next place is not skipped.

    Translate: one row per scorer and team in a CTE; then a ranking function, the one that does not skip a number after a tie (D10). `QUALIFY` keeps the ranks you want.

    > **Hint:** `ROW_NUMBER`, `RANK` and `DENSE_RANK` give three different answers to "what happens after a tie?" Suppose two players share second place with 8 goals each. On paper, write the number each function gives them, and the number it gives the next player with 7. Which one matches "share a place, and the next place is not skipped"? Run your ranking without `QUALIFY` first and look at the numbers.

    **Your result:** 4 rows:

    | Row | scorer | team | goals | goal_rank |
    |---:|---|---|---|---|
    | 1 | Kylian Mbappé | France | 10 | 1 |
    | 2 | Lionel Messi | Argentina | 8 | 2 |
    | 3 | Erling Haaland | Norway | 7 | 3 |
    | 4 | Jude Bellingham | England | 7 | 3 |


- **B2. "Is Jordan scoring more than it used to?"** For each year from 2015: Jordan's matches, goals scored, the change in goals on the year before, and the running total of goals since 2015.

    Translate: one row per year in a CTE, then `LAG` and a running total (D10). Look at 2020 before you write your sentence, and remember that 2026 ends on 30 September in this data, so it is not a full year.

    > **Hint:** `LAG` looks one row back, in the order you give it inside `OVER`. Run the CTE on its own first. Is every year there? If a year were missing, which year would `LAG` compare with? Your answer is the full query, not the CTE on its own.

    **Your result:** 12 rows. The first 5:

    | Row | year | matches | goals | change_on_last_year | running_goals |
    |---:|---|---|---|---|---|
    | 1 | 2015 | 17 | 28 | null | 28 |
    | 2 | 2016 | 12 | 17 | -11 | 45 |
    | 3 | 2017 | 11 | 21 | 4 | 66 |
    | 4 | 2018 | 13 | 11 | -10 | 77 |
    | 5 | 2019 | 19 | 28 | 17 | 105 |

- **B3. Penalty shootouts.** Jordan has gone to a penalty shootout five times. How many did it win? Which team has won the most shootouts of all time? This one asks two things, so two short queries are fine.

## How it is graded

| Criterion | Weight | Full marks when |
|---|---:|---|
| Correct results | 40% | Each query returns the right rows and values for its question (Part 1: 2 points each; questions 3–10: 4.5 points each) |
| Row counts | 20% | Every answer states its row count, and the Part 1 audits are there and agree with the data |
| The answer in words | 20% | Every answer has one sentence a non-technical manager could act on, with the number that supports it; question 9 says what the data can and cannot tell us |
| Readable SQL | 20% | CTEs and columns have names that say what one row is; aliases on every joined table; one clause per line; the file runs from top to bottom without errors |

A query that runs but answers a different question gets no marks for correctness, so reread each question before you move on. A query that has an error gets no marks for correctness but can still earn the other three.

## References

Mart Jürisoo, [International football results from 1872 to 2026](https://github.com/martj42/international_results), CC0 1.0. Course copy taken 9 October 2026 (matches to 30 September 2026); see [the dataset README](../../../../shared/datasets/intl_football/README.md) for what was changed.
