# Split by date, and two simple forecasts

In this activity, you will hold out 1959 and 1960 by date, then score two simple forecasts on 1959 in plain SQL: last month held flat, and the same month one year earlier.

**Time:** about 12 minutes · **Data:** `ml.air_training` (activity 02) and `ml.air_passengers` · **Starter:** `Unsolved/split_by_date.sql`

## The story

The model's forecast for 1959 looked plausible. To judge it you need two things: months it never saw, and a simple forecast that any planner could make without a model. If ARIMA_PLUS cannot beat "same month as last year", nobody needs it. The months you hold aside must come **after** the training months: a forecast is always made from the past.

## What you will learn

- To split a time series by date into training, validation and test months, and why a random split would cheat.
- To build the **naive** forecast (the last known value, held flat) and the **seasonal naive** forecast (the same month one year earlier) in SQL.
- To score a forecast with MAE (the average miss) and MAPE (the average miss as a percentage of the actual value).

## Before you start

You need `ml.air_training` from [activity 02](../02-Evr-First-Forecast/README.md), step 1. Check: `SELECT COUNT(*) FROM ml.air_training;` returns 120. If it is missing, run step 1 of activity 02, or [`Resources/restart_d15.sql`](../Resources/restart_d15.sql).

## Why by date, never at random

On D11 a random 20% of the people was held aside, and that was fair: one insured person tells you nothing about the next. Months are different. If July 1957 were held aside at random, June and August 1957 would still be in training, and the model would fill the gap from its neighbours on both sides. A real forecast never has next month to lean on. So the split is by date: every month before 1959-01-01 trains; 1959 is **validation** (compare and choose); 1960 is **test** (used once, at the end, as on D14). The **horizon**, how far ahead you forecast, is 12 months.

## Step 1 · The validation and test months

Run the two views as given, then count the three groups.

```sql
CREATE OR REPLACE VIEW ml.air_validation AS
SELECT month, passengers FROM ml.air_passengers
WHERE month >= '1959-01-01' AND month < '1960-01-01';

CREATE OR REPLACE VIEW ml.air_test AS
SELECT month, passengers FROM ml.air_passengers
WHERE month >= '1960-01-01';

SELECT 'training' AS air_group, COUNT(*) AS months FROM ml.air_training
UNION ALL
SELECT 'validation', COUNT(*) FROM ml.air_validation
UNION ALL
SELECT 'test', COUNT(*) FROM ml.air_test;
```

## Step 2 · The naive forecast: last month, held flat

The planner's simplest forecast: every month of 1959 will look like December 1958. First find that value:

```sql
SELECT month, passengers
FROM ml.air_training
ORDER BY month DESC
LIMIT 1;
```

Now score it on the twelve validation months. Fill in the blank with the value you just found (or, better, a subquery that finds it).

```sql
SELECT ROUND(AVG(ABS(v.passengers - ____)), 1) AS mae_naive,
       ROUND(100 * AVG(ABS(v.passengers - ____) / v.passengers), 1) AS mape_naive
FROM ml.air_validation AS v;
```

Translate: for each validation month, the miss is the actual value minus the forecast; drop the sign with `ABS`, then average.

## Step 3 · The seasonal naive forecast: same month, one year earlier

A better guess: January 1959 will look like January 1958, February like February, and so on. Each validation month needs the training month exactly one year before it.

```sql
SELECT ROUND(AVG(ABS(v.passengers - t.passengers)), 1) AS mae_seasonal_naive,
       ROUND(100 * AVG(ABS(v.passengers - t.passengers) / v.passengers), 1) AS mape_seasonal_naive
FROM ml.air_validation AS v
JOIN ml.air_training AS t
  ON t.month = ____;
```

Translate: which training month should January 1959 be compared with? Write the join so that every validation month finds it.

## Step 4 · The training mean, held flat

The guess from D11: the average of the training months, for every month.

```sql
SELECT ROUND(AVG(ABS(v.passengers - (SELECT ____ FROM ml.air_training))), 1) AS mae_training_mean,
       ROUND(100 * AVG(ABS(v.passengers - (SELECT ____ FROM ml.air_training)) / v.passengers), 1) AS mape_training_mean
FROM ml.air_validation AS v;
```

## Step 5 · The scoreboard

Write your three MAEs side by side, lowest first, and answer in one line each:

- Which simple forecast is the bar ARIMA_PLUS has to beat?
- Why does the seasonal naive miss by about half as much as the naive?
- Every one of the twelve seasonal-naive misses has the same sign. Which sign, and what does that say about the series?

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| 1 | 3 | training **120** · validation **12** · test **12** |
| 2 | 1 | last training month **1958-12-01**, **337** · naive MAE **91.3**, MAPE **19.5** |
| 3 | 1 | seasonal naive MAE **47.3**, MAPE **11.1** |
| 4 | 1 | training mean MAE **182.4**, MAPE **41.3** |
| Bonus | 1 | training median **233.5** · its MAE **194.8**, MAPE **44.2** |

The scores are in thousands of passengers a month. These are exact: no model is involved, so everyone gets the same values.

## Hint

`DATE_SUB(v.month, INTERVAL 1 YEAR)` is the date one year before `v.month`. A join on `t.month = v.month` returns nothing: the two views share no month.

## Bonus

When the score is MAE, the course also compares with the training **median** (D11). BigQuery's median is an analytic function, so it needs `OVER ()` and a `DISTINCT` to return one row:

```sql
SELECT DISTINCT PERCENTILE_CONT(passengers, 0.5) OVER () AS training_median
FROM ml.air_training;
```

Use it in step 4's query in place of the mean. Is the median better or worse than the mean here, and why does neither come close to the seasonal naive? (Answer: the median is 233.5 and misses 1959 by 194.8 on average, MAPE 44.2, worse than the mean. Both guess one flat number for a series that keeps growing.)

## References

Air Passengers: Box, Jenkins and Reinsel, *Time Series Analysis, Forecasting and Control* (1976), Series G, as listed on the [R datasets page](https://rweb.stat.umn.edu/R/library/datasets/html/AirPassengers.html); course copy in [`shared/datasets/ml_classics`](../../../../../shared/datasets/ml_classics/README.md), taken 19 October 2026.
