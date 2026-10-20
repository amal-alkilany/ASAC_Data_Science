-- D15 · Would you plan on this forecast? · Starter
-- Run one statement at a time, in order. CREATE MODEL and the ML. functions run in BigQuery only.
-- The README explains each step: read it first, run the SQL, then compare with "What you should see".

-- Step 2 · Optional: is the season growing?
SELECT EXTRACT(YEAR FROM month) AS year_number,
       MAX(passengers) - MIN(passengers) AS swing
FROM ml.air_passengers
WHERE month < '1960-01-01'
GROUP BY year_number
ORDER BY year_number;

-- Step 3 · Optional: how big a season did the model forecast?
SELECT ROUND(MAX(forecast_value) - MIN(forecast_value), 1) AS forecast_swing,
       ROUND(MAX(prediction_interval_upper_bound), 1) AS highest_upper_bound
FROM ML.FORECAST(MODEL ml.air_arima,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level));

-- Step 4 · Write three sentences
-- Write the three sentences in Unsolved/plan_on_the_forecast.md.

