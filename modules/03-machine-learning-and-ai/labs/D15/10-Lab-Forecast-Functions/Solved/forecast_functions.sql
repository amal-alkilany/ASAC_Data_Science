-- D15 · Lab 10 · Every function that reads an ARIMA_PLUS model · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time, after reading its step in the README.

-- Step 1 · ML.FORECAST with its defaults
SELECT *
FROM ML.FORECAST(MODEL ml.air_arima);

-- Step 2 · horizon
SELECT DATE(forecast_timestamp) AS month_forecast, ROUND(forecast_value, 1) AS forecast_passengers,
       ROUND(standard_error, 2) AS standard_error
FROM ML.FORECAST(MODEL ml.air_arima, STRUCT(12 AS horizon));

-- Step 3 · confidence_level
SELECT DATE(f80.forecast_timestamp) AS month_forecast,
       ROUND(f80.prediction_interval_upper_bound - f80.prediction_interval_lower_bound, 1) AS width_80,
       ROUND(f95.prediction_interval_upper_bound - f95.prediction_interval_lower_bound, 1) AS width_95,
       ROUND(f99.prediction_interval_upper_bound - f99.prediction_interval_lower_bound, 1) AS width_99
FROM ML.FORECAST(MODEL ml.air_arima, STRUCT(12 AS horizon, 0.8 AS confidence_level)) AS f80
JOIN ML.FORECAST(MODEL ml.air_arima, STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS f95
  ON f80.forecast_timestamp = f95.forecast_timestamp
JOIN ML.FORECAST(MODEL ml.air_arima, STRUCT(12 AS horizon, 0.99 AS confidence_level)) AS f99
  ON f80.forecast_timestamp = f99.forecast_timestamp
ORDER BY month_forecast;

-- Step 4 · The other columns
SELECT DATE(forecast_timestamp) AS month_forecast,
       ROUND(forecast_value, 1) AS forecast_passengers,
       ROUND(forecast_value - (prediction_interval_lower_bound + prediction_interval_upper_bound) / 2, 6) AS gap_to_middle,
       ROUND(prediction_interval_upper_bound - prediction_interval_lower_bound, 1) AS prediction_width,
       ROUND(confidence_interval_upper_bound - confidence_interval_lower_bound, 1) AS confidence_width
FROM ML.FORECAST(MODEL ml.air_arima, STRUCT(12 AS horizon, 0.95 AS confidence_level));

-- Step 5 · ML.EXPLAIN_FORECAST: history and forecast rows
SELECT time_series_type, COUNT(*) AS months,
       MIN(DATE(time_series_timestamp)) AS first_month, MAX(DATE(time_series_timestamp)) AS last_month,
       COUNTIF(confidence_level IS NULL) AS rows_without_level
FROM ML.EXPLAIN_FORECAST(MODEL ml.air_arima, STRUCT(12 AS horizon, 0.95 AS confidence_level))
GROUP BY time_series_type;

-- Step 6 · The parts add up
SELECT DATE(time_series_timestamp) AS month_history,
       time_series_data,
       ROUND(time_series_adjusted_data, 1) AS adjusted,
       ROUND(trend, 1) AS trend,
       ROUND(seasonal_period_yearly, 1) AS yearly,
       spikes_and_dips, step_changes,
       ROUND(residual, 1) AS residual,
       ROUND(time_series_data
             - (trend + IFNULL(seasonal_period_yearly, 0) + IFNULL(seasonal_period_quarterly, 0)
                + IFNULL(seasonal_period_monthly, 0) + IFNULL(seasonal_period_weekly, 0)
                + IFNULL(seasonal_period_daily, 0) + IFNULL(holiday_effect, 0)
                + IFNULL(spikes_and_dips, 0) + IFNULL(step_changes, 0) + IFNULL(residual, 0)), 6) AS left_over
FROM ML.EXPLAIN_FORECAST(MODEL ml.air_arima, STRUCT(12 AS horizon, 0.95 AS confidence_level))
WHERE time_series_type = 'history' AND EXTRACT(YEAR FROM time_series_timestamp) = 1958
ORDER BY month_history;

-- Step 7 · ML.DETECT_ANOMALIES on the training months
SELECT DATE(month) AS month_history, passengers, is_anomaly,
       ROUND(lower_bound, 1) AS lower_bound, ROUND(upper_bound, 1) AS upper_bound,
       ROUND(anomaly_probability, 3) AS anomaly_probability
FROM ML.DETECT_ANOMALIES(MODEL ml.air_arima)
WHERE is_anomaly
ORDER BY anomaly_probability DESC;

-- Step 8 · anomaly_prob_threshold
SELECT 0.8 AS threshold, COUNTIF(is_anomaly) AS months_flagged
FROM ML.DETECT_ANOMALIES(MODEL ml.air_arima, STRUCT(0.8 AS anomaly_prob_threshold))
UNION ALL
SELECT 0.95, COUNTIF(is_anomaly)
FROM ML.DETECT_ANOMALIES(MODEL ml.air_arima, STRUCT(0.95 AS anomaly_prob_threshold))
UNION ALL
SELECT 0.99, COUNTIF(is_anomaly)
FROM ML.DETECT_ANOMALIES(MODEL ml.air_arima, STRUCT(0.99 AS anomaly_prob_threshold))
ORDER BY threshold;

-- Step 9 · ML.DETECT_ANOMALIES on new months
SELECT month, passengers
FROM ml.air_validation
ORDER BY month;

SELECT DATE(month) AS month_new, passengers, is_anomaly,
       ROUND(lower_bound, 1) AS lower_bound, ROUND(upper_bound, 1) AS upper_bound
FROM ML.DETECT_ANOMALIES(MODEL ml.air_arima,
  STRUCT(0.95 AS anomaly_prob_threshold),
  (SELECT month, passengers FROM ml.air_validation))
ORDER BY month_new;

-- Step 10 · ML.ARIMA_EVALUATE
SELECT non_seasonal_p, non_seasonal_d, non_seasonal_q, has_drift,
       ROUND(log_likelihood, 1) AS log_likelihood, ROUND(AIC, 1) AS aic, ROUND(variance, 1) AS variance,
       seasonal_periods, has_holiday_effect, has_spikes_and_dips, has_step_changes, error_message
FROM ML.ARIMA_EVALUATE(MODEL ml.air_arima)
ORDER BY aic;

SELECT non_seasonal_p, non_seasonal_d, non_seasonal_q, has_drift, ROUND(AIC, 1) AS aic
FROM ML.ARIMA_EVALUATE(MODEL ml.air_arima, STRUCT(FALSE AS show_all_candidate_models));

-- Step 11 · ML.ARIMA_COEFFICIENTS
SELECT ar_coefficients, ma_coefficients, intercept_or_drift
FROM ML.ARIMA_COEFFICIENTS(MODEL ml.air_arima);

-- Step 12 · ML.EVALUATE, one score for the series
SELECT ROUND(mean_absolute_error, 1) AS mae,
       ROUND(root_mean_squared_error, 1) AS rmse,
       ROUND(mean_absolute_percentage_error, 2) AS mape,
       ROUND(symmetric_mean_absolute_percentage_error, 2) AS smape,
       ROUND(mean_absolute_scaled_error, 2) AS mase
FROM ML.EVALUATE(MODEL ml.air_arima,
  (SELECT month, passengers FROM ml.air_validation),
  STRUCT(TRUE AS perform_aggregation, 12 AS horizon));

SELECT ROUND(AVG(ABS(v.passengers - t.passengers)), 1) AS mae_seasonal_naive
FROM ml.air_validation AS v
JOIN ml.air_training AS t ON t.month = DATE_SUB(v.month, INTERVAL 1 YEAR);

-- Step 13 · ML.EVALUATE, month by month
SELECT DATE(month) AS month_scored, passengers,
       ROUND(forecasted_passengers, 1) AS forecasted_passengers,
       ROUND(lower_bound, 1) AS lower_bound, ROUND(upper_bound, 1) AS upper_bound,
       ROUND(absolute_error, 1) AS absolute_error,
       ROUND(absolute_percentage_error, 2) AS absolute_percentage_error
FROM ML.EVALUATE(MODEL ml.air_arima,
  (SELECT month, passengers FROM ml.air_validation),
  STRUCT(FALSE AS perform_aggregation, 0.9 AS confidence_level, 12 AS horizon))
ORDER BY month_scored;

-- Step 14 · ML.METRICS: score any forecast, with or without a model
CREATE OR REPLACE VIEW ml.air_baselines_1959 AS
SELECT v.month,
       CAST(v.passengers AS FLOAT64) AS actual_passengers,
       CAST((SELECT passengers FROM ml.air_training ORDER BY month DESC LIMIT 1) AS FLOAT64) AS naive_forecast,
       CAST(t.passengers AS FLOAT64) AS seasonal_naive_forecast
FROM ml.air_validation AS v
JOIN ml.air_training AS t ON t.month = DATE_SUB(v.month, INTERVAL 1 YEAR);

SELECT 'naive' AS forecast_method,
       ROUND(mean_absolute_error, 1) AS mae, ROUND(mean_squared_error, 1) AS mse,
       ROUND(mean_squared_log_error, 4) AS msle, ROUND(median_absolute_error, 1) AS median_ae,
       ROUND(r2_score, 3) AS r2, ROUND(explained_variance, 3) AS explained_variance
FROM ML.METRICS((SELECT actual_passengers, naive_forecast FROM ml.air_baselines_1959),
                predicted_col => 'naive_forecast', actual_col => 'actual_passengers',
                task_type => 'regression')
UNION ALL
SELECT 'seasonal naive',
       ROUND(mean_absolute_error, 1), ROUND(mean_squared_error, 1),
       ROUND(mean_squared_log_error, 4), ROUND(median_absolute_error, 1),
       ROUND(r2_score, 3), ROUND(explained_variance, 3)
FROM ML.METRICS((SELECT actual_passengers, seasonal_naive_forecast FROM ml.air_baselines_1959),
                predicted_col => 'seasonal_naive_forecast', actual_col => 'actual_passengers',
                task_type => 'regression');

WITH pairs AS (
  SELECT 'naive' AS forecast_method, actual_passengers AS actual, naive_forecast AS predicted
  FROM ml.air_baselines_1959
  UNION ALL
  SELECT 'seasonal naive', actual_passengers, seasonal_naive_forecast
  FROM ml.air_baselines_1959
),
misses AS (
  SELECT forecast_method, actual,
         actual - predicted AS miss,
         LN(1 + actual) - LN(1 + predicted) AS log_miss,
         AVG(actual) OVER (PARTITION BY forecast_method) AS mean_actual,
         AVG(actual - predicted) OVER (PARTITION BY forecast_method) AS mean_miss,
         PERCENTILE_CONT(ABS(actual - predicted), 0.5) OVER (PARTITION BY forecast_method) AS middle_miss
  FROM pairs
)
SELECT forecast_method,
       ROUND(AVG(ABS(miss)), 1) AS mae,
       ROUND(AVG(miss * miss), 1) AS mse,
       ROUND(AVG(log_miss * log_miss), 4) AS msle,
       ROUND(MAX(middle_miss), 1) AS median_ae,
       ROUND(1 - SUM(miss * miss) / SUM(POW(actual - mean_actual, 2)), 3) AS r2,
       ROUND(1 - SUM(POW(miss - mean_miss, 2)) / SUM(POW(actual - mean_actual, 2)), 3) AS explained_variance
FROM misses
GROUP BY forecast_method
ORDER BY forecast_method;

SELECT ROUND(mean_absolute_error, 1) AS mae, ROUND(median_absolute_error, 1) AS median_ae,
       ROUND(r2_score, 3) AS r2, ROUND(explained_variance, 3) AS explained_variance
FROM ML.METRICS(
  (SELECT CAST(v.passengers AS FLOAT64) AS actual_passengers, f.forecast_value
   FROM ML.FORECAST(MODEL ml.air_arima, STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS f
   JOIN ml.air_validation AS v ON DATE(f.forecast_timestamp) = v.month),
  predicted_col => 'forecast_value', actual_col => 'actual_passengers', task_type => 'regression');
