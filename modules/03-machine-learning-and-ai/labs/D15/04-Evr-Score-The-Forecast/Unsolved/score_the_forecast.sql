-- D15 · Score the forecast on 1959 · Starter
-- Run one statement at a time, in order. CREATE MODEL and the ML. functions run in BigQuery only.
-- The README explains each step: read it first, run the SQL, then compare with "What you should see".

-- Step 1 · The forecast beside the real months
SELECT DATE(f.forecast_timestamp) AS month_forecast, v.passengers,
       ROUND(f.forecast_value, 1) AS forecast_passengers,
       ROUND(v.passengers - f.forecast_value, 1) AS miss
FROM ML.FORECAST(MODEL ml.air_arima,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS f
JOIN ml.air_validation AS v
  ON DATE(f.forecast_timestamp) = v.month
ORDER BY month_forecast;

-- Step 2 · The score, and the bar
SELECT ROUND(AVG(ABS(v.passengers - f.forecast_value)), 1) AS mae,
       ROUND(100 * AVG(ABS(v.passengers - f.forecast_value) / v.passengers), 1) AS mape_pct
FROM ML.FORECAST(MODEL ml.air_arima,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS f
JOIN ml.air_validation AS v
  ON DATE(f.forecast_timestamp) = v.month;

SELECT 'naive: December 1958 held flat' AS forecast_method,
       ROUND(AVG(ABS(v.passengers - (SELECT passengers FROM ml.air_training ORDER BY month DESC LIMIT 1))), 1) AS mae,
       ROUND(100 * AVG(ABS(v.passengers - (SELECT passengers FROM ml.air_training ORDER BY month DESC LIMIT 1)) / v.passengers), 1) AS mape_pct
FROM ml.air_validation AS v
UNION ALL
SELECT 'seasonal naive: same month of 1958',
       ROUND(AVG(ABS(v.passengers - t.passengers)), 1),
       ROUND(100 * AVG(ABS(v.passengers - t.passengers) / v.passengers), 1)
FROM ml.air_validation AS v
JOIN ml.air_training AS t ON t.month = DATE_SUB(v.month, INTERVAL 1 YEAR)
UNION ALL
SELECT 'training mean held flat',
       ROUND(AVG(ABS(v.passengers - (SELECT AVG(passengers) FROM ml.air_training))), 1),
       ROUND(100 * AVG(ABS(v.passengers - (SELECT AVG(passengers) FROM ml.air_training)) / v.passengers), 1)
FROM ml.air_validation AS v
UNION ALL
SELECT 'training median held flat',
       ROUND(AVG(ABS(v.passengers - (SELECT DISTINCT PERCENTILE_CONT(passengers, 0.5) OVER () FROM ml.air_training))), 1),
       ROUND(100 * AVG(ABS(v.passengers - (SELECT DISTINCT PERCENTILE_CONT(passengers, 0.5) OVER () FROM ml.air_training)) / v.passengers), 1)
FROM ml.air_validation AS v
ORDER BY mae;

-- Step 3 · Reading the interval
SELECT COUNTIF(v.passengers BETWEEN f.prediction_interval_lower_bound
                                AND f.prediction_interval_upper_bound) AS months_inside
FROM ML.FORECAST(MODEL ml.air_arima,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS f
JOIN ml.air_validation AS v
  ON DATE(f.forecast_timestamp) = v.month;

-- Step 4 · Months that look unusual
SELECT DATE(time_series_timestamp) AS month_history, time_series_data,
       ROUND(trend, 1) AS trend, ROUND(seasonal_period_yearly, 1) AS season,
       spikes_and_dips, ROUND(residual, 1) AS residual
FROM ML.EXPLAIN_FORECAST(MODEL ml.air_arima,
                         STRUCT(12 AS horizon, 0.95 AS confidence_level))
WHERE time_series_type = 'history'
ORDER BY ABS(IFNULL(spikes_and_dips, 0) + IFNULL(residual, 0)) DESC
LIMIT 5;
