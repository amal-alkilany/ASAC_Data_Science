# Would you plan on this forecast?

In this activity, you and a partner will read the 1959 scores and intervals and write three sentences for the airline planner: which forecast to plan on, which bound to staff to, and one risk.

**Time:** about 12 minutes · **Data:** your results from activity 04; optional SQL on `ml.air_passengers` and `ml.air_arima` · **Worksheet:** `Unsolved/plan_on_the_forecast.md` · **Optional SQL:** `Unsolved/plan_on_the_forecast.sql`

## The story

The planner does not read MAE tables. She has to order aircraft time and roster crews for a year, and she asks three plain questions: *Which numbers should I plan on? How many people should I roster in the busy months? What could go wrong?* Your answer must stand on the 1959 evidence, because the test year has not been opened yet.

## What you will learn

- To turn a validation score into a recommendation a manager can act on.
- To choose between the forecast and its upper bound for different decisions.
- To name a risk from the pattern of the misses, not only their size.

## Before you start

You need your results from [activity 04](../04-Evr-Score-The-Forecast/README.md): the model's MAE and MAPE on 1959, the four simple forecasts' scores, and how many of the 12 months fell inside the 95% interval. The optional SQL in steps 2 and 3 needs `ml.air_passengers` (activity 01) and `ml.air_arima` (activity 02); if anything is missing, run [`Resources/restart_d15.sql`](../Resources/restart_d15.sql).

## Step 1 · Read the evidence

Copy your numbers into the worksheet's first table. The simple forecasts are exact; the model's values below were computed outside BigQuery with a similar method, so use yours.

| Forecast for 1959 | MAE (thousands a month) | MAPE |
|---|---:|---:|
| ARIMA_PLUS | yours (about 27) | yours (about 6.2%) |
| seasonal naive: same month of 1958 | 47.3 | 11.1% |
| naive: December 1958 held flat | 91.3 | 19.5% |
| training mean held flat | 182.4 | 41.3% |
| training median held flat | 194.8 | 44.2% |

Then look at activity 04's step 1 again: in which months were the largest misses, and in which direction?

## Step 2 · Optional: is the season growing?

```sql
SELECT EXTRACT(YEAR FROM month) AS year_number,
       MAX(passengers) - MIN(passengers) AS swing
FROM ml.air_passengers
WHERE month < '1960-01-01'
GROUP BY year_number
ORDER BY year_number;
```

The swing is the gap between the busiest and the quietest month of a year. The `WHERE` stops before 1960: the test year stays closed.

**What you should see:** 11 rows, the swing growing from 44 in 1949 to 195 in 1958 and 217 in 1959.

## Step 3 · Optional: how big a season did the model forecast?

```sql
SELECT ROUND(MAX(forecast_value) - MIN(forecast_value), 1) AS forecast_swing,
       ROUND(MAX(prediction_interval_upper_bound), 1) AS highest_upper_bound
FROM ML.FORECAST(MODEL ml.air_arima,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level));
```

**What you should see:** one row. Computed outside BigQuery with a similar method, the forecast's swing for 1959 was about 191, close to the swing of the training years and well short of the real 217. ARIMA_PLUS adds the season back as a fixed amount learned from the past; when the season keeps growing, the next peak comes in above the forecast.

## Step 4 · Write three sentences

With your partner, write in the worksheet:

1. **Which forecast to plan on**, with its 1959 score in the planner's units.
2. **Which bound to staff to**, and in which months.
3. **One risk**, from the pattern of the misses.

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| 2 | 11 | 1949 **44** · 1958 **195** · 1959 **217** |

A fair answer names ARIMA_PLUS, gives its miss as a number of passengers, uses the upper bound for crews in the summer, and names the growing season as the risk.

## Hint

A risk is something that would make the plan wrong in a predictable direction. Look at the signs of the misses before you look at their size.

## Bonus

Would your recommendation change if the planner cared about revenue (where too high and too low cost the same) rather than crews (where too few costs much more than too many)? Say which number you would hand her in each case.

## References

Air Passengers: Box, Jenkins and Reinsel, *Time Series Analysis, Forecasting and Control* (1976), Series G, as listed on the [R datasets page](https://rweb.stat.umn.edu/R/library/datasets/html/AirPassengers.html); course copy in [`shared/datasets/ml_classics`](../../../../../shared/datasets/ml_classics/README.md), taken 19 October 2026. BigQuery ML: [ML.FORECAST](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-forecast), Google Cloud.
