# A prepared forecast

In this activity, you will train a prepared ARIMA_PLUS model on the 120 months before 1959, ask it for the next 12 months, and read the forecast and its interval.

**Time:** about 14 minutes in class, following along · **Data:** `ml.air_passengers` (activity 01) → the view `ml.air_training` · **Starter:** `Unsolved/first_forecast.sql`

## The story

The planner asked for next year's monthly passengers. Before any theory, you build the forecast and look at it. You give the model the months up to the end of 1958 and ask for the twelve months of 1959, a year you have the real numbers for, so that later today you can check the forecast against what happened.

## What you will learn

- To train an `ARIMA_PLUS` model with four options: the model type, the time column, the column to forecast and the horizon.
- To ask for a forecast with `ML.FORECAST`, passing `horizon` and `confidence_level` in a `STRUCT`.
- To read `forecast_value` and the prediction interval around it.

## Before you start

You need `ml.air_passengers` from [activity 01](../01-Evr-Monthly-Series/README.md). Check: `SELECT COUNT(*) FROM ml.air_passengers;` returns 144. If it is missing, upload `air_passengers.csv` as activity 01 describes.

ARIMA_PLUS is what Google calls a *built-in* model: it trains inside BigQuery, so it trains in a sandbox project. Training reads the 120 rows several times (it tries several candidate models), which on a table this small is a tiny share of the free monthly allowance.

## Step 1 · The training months

```sql
CREATE OR REPLACE VIEW ml.air_training AS
SELECT month, passengers
FROM ml.air_passengers
WHERE month < '1959-01-01';

SELECT COUNT(*) AS months, MIN(month) AS first_month, MAX(month) AS last_month
FROM ml.air_training;
```

The model learns from every month before the cutoff, 1959-01-01, and nothing after it. Why not a random 80% of the months, as on D11? Hold that question: activity 03 answers it.

**What you should see:** 120 months, from 1949-01-01 to 1958-12-01.

## Step 2 · A prepared model

```sql
CREATE OR REPLACE MODEL ml.air_arima
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12) AS
SELECT month, passengers FROM ml.air_training;
```

Read the options before you run it:

| Option | Here | What it does |
|---|---|---|
| `MODEL_TYPE` | `'ARIMA_PLUS'` | a model for one or many time series |
| `TIME_SERIES_TIMESTAMP_COL` | `'month'` | the column with the time points; it must be a DATE, DATETIME or TIMESTAMP |
| `TIME_SERIES_DATA_COL` | `'passengers'` | the column to forecast |
| `HORIZON` | `12` | how many months ahead the model prepares; the default is 1,000 |

There is no `input_label_cols`: the series is its own label. The model learns from the past values of `passengers` and nothing else.

**What you should see:** the job runs for a short while, then `air_arima` appears under `ml` with the other models.

## Step 3 · Twelve months ahead

```sql
SELECT forecast_timestamp, forecast_value,
       prediction_interval_lower_bound, prediction_interval_upper_bound
FROM ML.FORECAST(MODEL ml.air_arima,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level));
```

`horizon` is how many months to return; leave it out and you get 3, its default. `confidence_level` is the width of the interval; 0.95 is the default, written out here so you can see it.

| Column | Read it as |
|---|---|
| `forecast_timestamp` | the month forecast. Always a TIMESTAMP, even though `month` is a DATE (Google's page says so); `DATE(forecast_timestamp)` turns it back into a date |
| `forecast_value` | the forecast: the middle of the interval |
| `prediction_interval_lower_bound`, `prediction_interval_upper_bound` | the range the model expects that month's real value to fall in, at the 95% level |

**What you should see:** 12 rows, January to December 1959. The forecast climbs and has a summer peak, and the interval gets wider month by month. Computed outside BigQuery with a similar method, the forecast was about 353 for January and about 523 for August; BigQuery chooses its own settings, so yours will differ a little.

## Step 4 · The forecast beside the last year of history

```sql
SELECT month AS series_month, passengers AS series_value, 'history' AS row_type
FROM ml.air_training
WHERE month >= '1958-01-01'
UNION ALL
SELECT DATE(forecast_timestamp), ROUND(forecast_value, 1), 'forecast'
FROM ML.FORECAST(MODEL ml.air_arima,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level))
ORDER BY series_month;
```

Twelve months of 1958, then the twelve forecast months of 1959, in one list. Open **Chart** on the result to see them as a line.

**What you should see:** 24 rows. The 1959 forecast follows the 1958 shape, a little higher.

**Think:** the forecast looks plausible. How would you know whether it is any good? On D14 you scored models on rows they never saw and compared them with a simple guess. Which months can you hold aside here, and what is the simple guess to beat? Activities 03 and 04 answer both.

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| 1 | 1 | **120** months, **1949-01-01** to **1958-12-01** |

Step 3 returns 12 rows, one per month of 1959, with values that depend on the model BigQuery chooses.

## If something goes wrong

- **`CREATE MODEL` stops with a message about the type of `month`:** `month` is STRING; the time column must be a DATE, DATETIME or TIMESTAMP. Upload `air_passengers.csv` again with the schema set by hand (activity 01).
- **`ML.FORECAST` returns 3 rows:** the `STRUCT` is missing `12 AS horizon`.
- **A message that the horizon is too large:** `ML.FORECAST` cannot go past the `HORIZON` set in `CREATE MODEL` (here 12).

## Hint

`ML.FORECAST` takes the model and one `STRUCT` of settings; every setting inside it is written `value AS name`.

## Bonus

Ask for an 80% interval instead: `STRUCT(12 AS horizon, 0.8 AS confidence_level)`. Is it wider or narrower than the 95% one, and why would a narrower interval be riskier for staffing?

## References

Air Passengers: Box, Jenkins and Reinsel, *Time Series Analysis, Forecasting and Control* (1976), Series G, as listed on the [R datasets page](https://rweb.stat.umn.edu/R/library/datasets/html/AirPassengers.html); course copy in [`shared/datasets/ml_classics`](../../../../../shared/datasets/ml_classics/README.md), taken 19 October 2026. BigQuery ML: [CREATE MODEL for ARIMA_PLUS](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-time-series), [ML.FORECAST](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-forecast), [BigQuery ML pricing](https://cloud.google.com/bigquery/pricing#bqml) (built-in and external models), Google Cloud.
