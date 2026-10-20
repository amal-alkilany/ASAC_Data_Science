# A monthly series: load it and look at it

In this activity, you will upload twelve years of monthly airline passengers to BigQuery, check that one row is one month with none missing, and see the trend and the season in two small queries.

**Time:** about 12 minutes in class, following along · **Data:** `air_passengers.csv` → `ml.air_passengers` · **Starter:** `Unsolved/monthly_series.sql`

## The story

An airline planner wants next year's monthly passenger numbers, to plan aircraft and crews. She has the history: the number of international airline passengers in every month from January 1949 to December 1960, in thousands. Before anyone forecasts anything, you check what the table holds. On D11 to D14 one row was one person, and the order of the rows did not matter. Here one row is one month, and the order is the whole point.

## What you will learn

- To upload a table with a DATE column and check its first and last month.
- Why "one row is one month, and no month is missing" is the first check for any series you want to forecast.
- To see a **trend** (each year higher than the last) and a **season** (a summer peak every year) with `GROUP BY`.

## Before you start

You need the `ml` dataset from D11. If it is missing: `CREATE SCHEMA IF NOT EXISTS ml OPTIONS (location = 'US');`

Download [`air_passengers.csv`](../../../../../shared/datasets/ml_classics/air_passengers.csv) and upload it as `air_passengers` in `ml`: next to `ml`, **⋮** → **Create table**, **Create table from:** Upload, **File format:** CSV, **Table:** `air_passengers`, tick **Auto detect**. Then open the table's **Schema** tab: `month` must be DATE and `passengers` INTEGER. If `month` shows STRING, delete the table and upload again with the schema set by hand (`month` DATE, `passengers` INTEGER).

If you uploaded it before, check it with step 1.

## Step 1 · How many months, from when to when

Ask first: one row is one ___? A month. How many rows should there be? Twelve years of twelve months.

```sql
SELECT COUNT(*) AS months, MIN(month) AS first_month, MAX(month) AS last_month
FROM ml.air_passengers;
```

**What you should see:** one row: 144 months, from 1949-01-01 to 1960-12-01. Each month is stored as its first day.

## Step 2 · No month missing, none twice

```sql
SELECT DATE_DIFF(MAX(month), MIN(month), MONTH) + 1 AS months_in_range,
       COUNT(DISTINCT month) AS distinct_months
FROM ml.air_passengers;
```

`DATE_DIFF(…, MONTH)` counts the months between the first and the last; adding 1 counts both ends. If the table had a gap, `months_in_range` would be larger than the number of distinct months. If a month appeared twice, `COUNT(*)` from step 1 would be larger than `distinct_months`.

Why check this yourself: Google's page for ARIMA_PLUS says the model will "Interpolate missing data using local linear interpolation" and "Handle duplicated timestamps by taking the mean value". A missing or doubled month would not stop the model; it would be filled in or averaged without a message. You want to know before that happens.

**What you should see:** 144 and 144. No gaps, no doubles.

## Step 3 · The trend: one row per year

```sql
SELECT EXTRACT(YEAR FROM month) AS year_number, SUM(passengers) AS yearly_total
FROM ml.air_passengers
GROUP BY year_number
ORDER BY year_number;
```

`EXTRACT(YEAR FROM month)` takes the year out of the date (D06); grouping by it adds up the twelve months of each year.

**What you should see:** 12 rows, from 1,520 (thousand passengers) in 1949 to 5,714 in 1960. Every year is higher than the year before. That steady climb is the **trend**.

## Step 4 · The season: the same shape every year

```sql
SELECT EXTRACT(MONTH FROM month) AS month_of_year,
       ROUND(AVG(passengers), 1) AS average_passengers
FROM ml.air_passengers
WHERE month < '1959-01-01'
GROUP BY month_of_year
ORDER BY month_of_year;
```

The `WHERE` keeps the months before 1959, the ones the model will learn from today (activity 03 explains why the last two years stay aside).

**What you should see:** 12 rows. July (304.6) and August (304.8) are the busiest months on average, November (204.2) the quietest. A pattern that repeats every year at the same time is the **season**.

## Step 5 · Does the season grow?

```sql
SELECT EXTRACT(YEAR FROM month) AS year_number,
       MIN(passengers) AS quietest_month,
       MAX(passengers) AS busiest_month,
       MAX(passengers) - MIN(passengers) AS swing
FROM ml.air_passengers
WHERE month < '1959-01-01'
GROUP BY year_number
ORDER BY year_number;
```

**What you should see:** 10 rows. In 1949 the busiest month was 44 thousand above the quietest; in 1958, 195 thousand. The summer peak grows as the airline grows. Keep this in mind: it is the main weakness of today's forecast.

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| 1 | 1 | **144** months, **1949-01-01** to **1960-12-01** |
| 2 | 1 | **144** and **144** |
| 3 | 12 | 1949: **1,520** · 1960: **5,714** |
| 4 | 12 | August **304.8** · November **204.2** |
| 5 | 10 | 1949 swing **44** · 1958 swing **195** |

## If something goes wrong

- **`No matching signature for function DATE_DIFF` or `EXTRACT`:** `month` was uploaded as STRING. Upload again with the schema set by hand (see Before you start).
- **Step 1 shows 145 rows:** the header row was read as data. Upload again with **Auto detect** ticked, or set **Header rows to skip** to 1.

## Hint

`EXTRACT(YEAR FROM month)` and `EXTRACT(MONTH FROM month)` both return a whole number: the year (1949) or the month of the year (1 to 12).

## Bonus

Which single month was the busiest of all twelve years, and which the quietest? Sort the table by `passengers`. (Answer: July 1960 with 622, and November 1949 with 104.)

## References

Monthly totals of international airline passengers, 1949 to 1960: Box, Jenkins and Reinsel, *Time Series Analysis, Forecasting and Control* (1976), Series G, as listed on the [R datasets page](https://rweb.stat.umn.edu/R/library/datasets/html/AirPassengers.html). Course copy [`air_passengers.csv`](../../../../../shared/datasets/ml_classics/air_passengers.csv) in [`shared/datasets/ml_classics`](../../../../../shared/datasets/ml_classics/README.md), taken 19 October 2026. BigQuery ML: [CREATE MODEL for ARIMA_PLUS](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-time-series) (how missing and duplicated months are handled), Google Cloud.
