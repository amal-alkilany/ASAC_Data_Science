-- D15 · A prepared forecast · Solved (every query from the README, in order)
-- Run one statement at a time, in order. CREATE MODEL and the ML. functions run in BigQuery only.

-- Step 1 · The training months
CREATE OR REPLACE VIEW ml.air_training AS
SELECT month, passengers
FROM ml.air_passengers
WHERE month < '1959-01-01';

SELECT COUNT(*) AS months, MIN(month) AS first_month, MAX(month) AS last_month
FROM ml.air_training;

-- Step 2 · A prepared model
CREATE OR REPLACE MODEL ml.air_arima
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12) AS
SELECT month, passengers FROM ml.air_training;

-- Step 3 · Twelve months ahead
SELECT forecast_timestamp, forecast_value,
       prediction_interval_lower_bound, prediction_interval_upper_bound
FROM ML.FORECAST(MODEL ml.air_arima,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level));

-- Step 4 · The forecast beside the last year of history
SELECT month AS series_month, passengers AS series_value, 'history' AS row_type
FROM ml.air_training
WHERE month >= '1958-01-01'
UNION ALL
SELECT DATE(forecast_timestamp), ROUND(forecast_value, 1), 'forecast'
FROM ML.FORECAST(MODEL ml.air_arima,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level))
ORDER BY series_month;
