-- D15 · The test year, once · Solved (every query from the README, in order)
-- Run one statement at a time, in order. CREATE MODEL and the ML. functions run in BigQuery only.

-- Step 1 · Retrain on every month before the test
CREATE OR REPLACE MODEL ml.air_arima_final
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12) AS
SELECT month, passengers FROM ml.air_passengers
WHERE month < '1960-01-01';

-- Step 2 · Forecast 1960 and score it, once
SELECT ROUND(AVG(ABS(te.passengers - f.forecast_value)), 1) AS mae_arima,
       ROUND(100 * AVG(ABS(te.passengers - f.forecast_value) / te.passengers), 1) AS mape_arima_pct,
       ROUND(AVG(ABS(te.passengers - v.passengers)), 1) AS mae_seasonal_naive,
       COUNTIF(te.passengers BETWEEN f.prediction_interval_lower_bound
                                 AND f.prediction_interval_upper_bound) AS months_inside
FROM ML.FORECAST(MODEL ml.air_arima_final,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS f
JOIN ml.air_test AS te ON DATE(f.forecast_timestamp) = te.month
JOIN ml.air_validation AS v ON v.month = DATE_SUB(te.month, INTERVAL 1 YEAR);

-- Step 3 · The bar for 1960, in full
SELECT 'seasonal naive: same month of 1959' AS forecast_method,
       ROUND(AVG(ABS(te.passengers - v.passengers)), 1) AS mae,
       ROUND(100 * AVG(ABS(te.passengers - v.passengers) / te.passengers), 1) AS mape_pct
FROM ml.air_test AS te
JOIN ml.air_validation AS v ON v.month = DATE_SUB(te.month, INTERVAL 1 YEAR)
UNION ALL
SELECT 'naive: December 1959 held flat',
       ROUND(AVG(ABS(te.passengers - (SELECT passengers FROM ml.air_validation ORDER BY month DESC LIMIT 1))), 1),
       ROUND(100 * AVG(ABS(te.passengers - (SELECT passengers FROM ml.air_validation ORDER BY month DESC LIMIT 1)) / te.passengers), 1)
FROM ml.air_test AS te
ORDER BY mae;
