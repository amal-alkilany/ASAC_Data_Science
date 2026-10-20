-- D15 · Lab 09 · ARIMA_PLUS, option by option · Starter
-- Self-guided: run one statement at a time, after reading its step in the README.
-- The README explains each step: read it first, run the SQL, then compare with "What you should see".

-- Step 1 · The bar, and one scoring query
SELECT ROUND(AVG(ABS(v.passengers - t.passengers)), 1) AS mae_seasonal_naive
FROM ml.air_validation AS v
JOIN ml.air_training AS t ON t.month = DATE_SUB(v.month, INTERVAL 1 YEAR);

SELECT ROUND(AVG(ABS(v.passengers - f.forecast_value)), 1) AS validation_mae
FROM ML.FORECAST(MODEL ml.air_arima, STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS f
JOIN ml.air_validation AS v ON DATE(f.forecast_timestamp) = v.month;

-- Step 2 · Every default, written out (C1)
CREATE OR REPLACE MODEL ml.air_defaults
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         AUTO_ARIMA = TRUE,
         AUTO_ARIMA_MAX_ORDER = 2,
         AUTO_ARIMA_MIN_ORDER = 0,
         DATA_FREQUENCY = 'AUTO_FREQUENCY',
         SEASONALITIES = ['AUTO'],
         CLEAN_SPIKES_AND_DIPS = TRUE,
         ADJUST_STEP_CHANGES = TRUE,
         DECOMPOSE_TIME_SERIES = TRUE) AS
SELECT month, passengers FROM ml.air_training;

-- Step 3 · What did the model choose?
SELECT non_seasonal_p, non_seasonal_d, non_seasonal_q, has_drift,
       ROUND(AIC, 1) AS aic, seasonal_periods,
       has_spikes_and_dips, has_step_changes, has_holiday_effect
FROM ML.ARIMA_EVALUATE(MODEL ml.air_defaults, STRUCT(FALSE AS show_all_candidate_models));

-- Step 4 · MODEL_TYPE, TIME_SERIES_TIMESTAMP_COL and TIME_SERIES_DATA_COL
CREATE OR REPLACE MODEL ml.air_timestamp
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month_start',
         TIME_SERIES_DATA_COL = 'passengers_float',
         HORIZON = 12) AS
SELECT TIMESTAMP(month) AS month_start, CAST(passengers AS FLOAT64) AS passengers_float
FROM ml.air_training;

-- Step 5 · HORIZON
CREATE OR REPLACE MODEL ml.air_horizon24
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 24) AS
SELECT month, passengers FROM ml.air_training;

SELECT DATE(forecast_timestamp) AS month_forecast, ROUND(forecast_value, 1) AS forecast_value,
       ROUND(prediction_interval_upper_bound - prediction_interval_lower_bound, 1) AS interval_width
FROM ML.FORECAST(MODEL ml.air_horizon24, STRUCT(24 AS horizon, 0.95 AS confidence_level));

-- Step 6 · AUTO_ARIMA_MAX_ORDER and AUTO_ARIMA_MIN_ORDER
CREATE OR REPLACE MODEL ml.air_order5
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         AUTO_ARIMA_MAX_ORDER = 5) AS
SELECT month, passengers FROM ml.air_training;

SELECT non_seasonal_p, non_seasonal_d, non_seasonal_q, has_drift, ROUND(AIC, 1) AS aic, error_message
FROM ML.ARIMA_EVALUATE(MODEL ml.air_order5, STRUCT(TRUE AS show_all_candidate_models))
ORDER BY aic;

-- Step 7 · AUTO_ARIMA, NON_SEASONAL_ORDER and INCLUDE_DRIFT
CREATE OR REPLACE MODEL ml.air_manual
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         AUTO_ARIMA = FALSE,
         NON_SEASONAL_ORDER = (1, 1, 0),
         INCLUDE_DRIFT = TRUE) AS
SELECT month, passengers FROM ml.air_training;

-- Step 8 · DATA_FREQUENCY
CREATE OR REPLACE MODEL ml.air_monthly
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         DATA_FREQUENCY = 'MONTHLY') AS
SELECT month, passengers FROM ml.air_training;

-- Step 9 · SEASONALITIES
CREATE OR REPLACE MODEL ml.air_noseason
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         SEASONALITIES = ['NO_SEASONALITY']) AS
SELECT month, passengers FROM ml.air_training;

-- Step 10 · CLEAN_SPIKES_AND_DIPS and ADJUST_STEP_CHANGES
CREATE OR REPLACE MODEL ml.air_raw
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         CLEAN_SPIKES_AND_DIPS = FALSE,
         ADJUST_STEP_CHANGES = FALSE) AS
SELECT month, passengers FROM ml.air_training;

SELECT COUNTIF(spikes_and_dips IS NOT NULL AND spikes_and_dips != 0) AS months_cleaned,
       COUNTIF(step_changes IS NOT NULL AND step_changes != 0) AS months_with_step_change
FROM ML.EXPLAIN_FORECAST(MODEL ml.air_defaults, STRUCT(12 AS horizon, 0.95 AS confidence_level))
WHERE time_series_type = 'history';

-- Step 11 · DECOMPOSE_TIME_SERIES
CREATE OR REPLACE MODEL ml.air_nodecomp
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         DECOMPOSE_TIME_SERIES = FALSE) AS
SELECT month, passengers FROM ml.air_training;

SELECT *
FROM ML.EXPLAIN_FORECAST(MODEL ml.air_nodecomp, STRUCT(12 AS horizon, 0.95 AS confidence_level));

-- Step 12 · TREND_SMOOTHING_WINDOW_SIZE
CREATE OR REPLACE MODEL ml.air_smooth
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         TREND_SMOOTHING_WINDOW_SIZE = 12) AS
SELECT month, passengers FROM ml.air_training;

SELECT DATE(d.time_series_timestamp) AS month_history,
       ROUND(d.trend, 1) AS trend_default, ROUND(s.trend, 1) AS trend_smoothed
FROM ML.EXPLAIN_FORECAST(MODEL ml.air_defaults, STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS d
JOIN ML.EXPLAIN_FORECAST(MODEL ml.air_smooth, STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS s
  ON d.time_series_timestamp = s.time_series_timestamp
WHERE d.time_series_type = 'history' AND EXTRACT(YEAR FROM d.time_series_timestamp) = 1955
ORDER BY month_history;

-- Step 13 · TIME_SERIES_LENGTH_FRACTION, MIN_TIME_SERIES_LENGTH and MAX_TIME_SERIES_LENGTH
CREATE OR REPLACE MODEL ml.air_recent_half
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         TIME_SERIES_LENGTH_FRACTION = 0.5,
         MIN_TIME_SERIES_LENGTH = 36) AS
SELECT month, passengers FROM ml.air_training;

CREATE OR REPLACE MODEL ml.air_recent_30
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         MAX_TIME_SERIES_LENGTH = 30) AS
SELECT month, passengers FROM ml.air_training;

-- Step 14 · FORECAST_LIMIT_LOWER_BOUND and FORECAST_LIMIT_UPPER_BOUND
CREATE OR REPLACE MODEL ml.air_bounded
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         FORECAST_LIMIT_LOWER_BOUND = 0,
         FORECAST_LIMIT_UPPER_BOUND = 1000) AS
SELECT month, passengers FROM ml.air_training;

-- Step 15 · Forecast the logarithm (C3)
SELECT month, passengers, ROUND(LN(passengers), 3) AS log_passengers
FROM ml.air_training
ORDER BY month;

CREATE OR REPLACE MODEL ml.air_log
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'log_passengers',
         HORIZON = 12) AS
SELECT month, LN(passengers) AS log_passengers FROM ml.air_training;

SELECT ROUND(AVG(ABS(v.passengers - EXP(f.forecast_value))), 1) AS validation_mae,
       COUNTIF(v.passengers BETWEEN EXP(f.prediction_interval_lower_bound)
                                AND EXP(f.prediction_interval_upper_bound)) AS months_inside
FROM ML.FORECAST(MODEL ml.air_log, STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS f
JOIN ml.air_validation AS v ON DATE(f.forecast_timestamp) = v.month;

-- Step 16 · HOLIDAY_REGION
CREATE OR REPLACE MODEL ml.air_holiday
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12,
         HOLIDAY_REGION = 'GLOBAL') AS
SELECT month, passengers FROM ml.air_training;

-- Step 17 · TIME_SERIES_ID_COL: many series in one model
CREATE OR REPLACE VIEW ml.channel_revenue AS
SELECT DATE_TRUNC(order_date, MONTH) AS order_month, channel,
       SUM(order_total) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY order_month, channel;

SELECT channel, COUNT(*) AS months, ROUND(SUM(revenue), 2) AS total_revenue
FROM ml.channel_revenue
GROUP BY channel
ORDER BY channel;

CREATE OR REPLACE MODEL ml.channel_arima
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'order_month',
         TIME_SERIES_DATA_COL = 'revenue',
         TIME_SERIES_ID_COL = 'channel',
         HORIZON = 6) AS
SELECT order_month, channel, revenue FROM ml.channel_revenue;

SELECT channel, DATE(forecast_timestamp) AS month_forecast, ROUND(forecast_value, 2) AS forecast_value
FROM ML.FORECAST(MODEL ml.channel_arima, STRUCT(6 AS horizon, 0.95 AS confidence_level))
ORDER BY channel, month_forecast;
