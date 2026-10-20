-- D15 · Lab 13 (optional, self-study) · Nakheel's daily revenue · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time, after reading its step in the README.

-- Step 1 · What counts as revenue
SELECT status, COUNT(*) AS order_count, MIN(order_date) AS first_day, MAX(order_date) AS last_day
FROM nakheel.orders
GROUP BY status
ORDER BY order_count DESC;

-- Step 2 · One row per day
CREATE OR REPLACE VIEW ml.nakheel_daily AS
SELECT order_day,
       IFNULL(SUM(o.order_total), 0) AS revenue,
       COUNT(o.order_id) AS completed_orders
FROM UNNEST(GENERATE_DATE_ARRAY('2024-09-01', '2026-08-31')) AS order_day
LEFT JOIN nakheel.orders AS o
  ON o.order_date = order_day AND o.status = 'completed'
GROUP BY order_day;

SELECT COUNT(*) AS days, MIN(order_day) AS first_day, MAX(order_day) AS last_day,
       COUNTIF(revenue = 0) AS days_without_revenue,
       ROUND(AVG(revenue), 2) AS average_day, MAX(revenue) AS best_day_revenue,
       ROUND(SUM(revenue), 2) AS total_revenue
FROM ml.nakheel_daily;

-- Step 3 · Look before you model
SELECT order_day, revenue, completed_orders
FROM ml.nakheel_daily
WHERE order_day >= '2026-08-20'
ORDER BY order_day;

SELECT FORMAT_DATE('%A', order_day) AS weekday, ROUND(AVG(revenue), 2) AS average_revenue, COUNT(*) AS days
FROM ml.nakheel_daily
WHERE order_day < '2026-08-01'
GROUP BY weekday
ORDER BY average_revenue DESC;

-- Step 4 · Split by date
CREATE OR REPLACE VIEW ml.revenue_training AS
SELECT order_day, revenue FROM ml.nakheel_daily
WHERE order_day < '2026-08-01';

CREATE OR REPLACE VIEW ml.revenue_validation AS
SELECT order_day, revenue FROM ml.nakheel_daily
WHERE order_day >= '2026-08-01' AND order_day < '2026-08-27';

SELECT 'training' AS revenue_group, COUNT(*) AS days, ROUND(AVG(revenue), 2) AS average_day FROM ml.revenue_training
UNION ALL
SELECT 'validation', COUNT(*), ROUND(AVG(revenue), 2) FROM ml.revenue_validation;

-- Step 5 · Three simple forecasts
SELECT 'naive: 31 July held flat' AS forecast_method,
       ROUND(AVG(ABS(v.revenue - (SELECT revenue FROM ml.revenue_training ORDER BY order_day DESC LIMIT 1))), 2) AS mae
FROM ml.revenue_validation AS v
UNION ALL
SELECT 'seasonal naive: same weekday, last training week',
       ROUND(AVG(ABS(v.revenue - t.revenue)), 2)
FROM ml.revenue_validation AS v
JOIN ml.revenue_training AS t
  ON t.order_day >= '2026-07-25'
 AND FORMAT_DATE('%A', t.order_day) = FORMAT_DATE('%A', v.order_day)
UNION ALL
SELECT 'training mean held flat',
       ROUND(AVG(ABS(v.revenue - (SELECT AVG(revenue) FROM ml.revenue_training))), 2)
FROM ml.revenue_validation AS v
ORDER BY mae;

-- Step 6 · ARIMA_PLUS, daily
CREATE OR REPLACE MODEL ml.revenue_arima
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'order_day',
         TIME_SERIES_DATA_COL = 'revenue',
         DATA_FREQUENCY = 'DAILY',
         HORIZON = 30) AS
SELECT order_day, revenue FROM ml.revenue_training;

SELECT non_seasonal_p, non_seasonal_d, non_seasonal_q, has_drift, seasonal_periods,
       has_spikes_and_dips, has_step_changes
FROM ML.ARIMA_EVALUATE(MODEL ml.revenue_arima, STRUCT(FALSE AS show_all_candidate_models));

-- Step 7 · Score it on 1 to 26 August
SELECT ROUND(AVG(ABS(v.revenue - f.forecast_value)), 2) AS mae_arima,
       COUNTIF(v.revenue BETWEEN f.prediction_interval_lower_bound
                             AND f.prediction_interval_upper_bound) AS days_inside,
       COUNTIF(f.prediction_interval_lower_bound < 0) AS days_lower_bound_below_zero
FROM ML.FORECAST(MODEL ml.revenue_arima, STRUCT(26 AS horizon, 0.95 AS confidence_level)) AS f
JOIN ml.revenue_validation AS v ON DATE(f.forecast_timestamp) = v.order_day;

-- Step 8 · Optional: Jordan's holidays as a custom holiday table
CREATE OR REPLACE MODEL ml.revenue_arima_eid
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'order_day',
         TIME_SERIES_DATA_COL = 'revenue',
         DATA_FREQUENCY = 'DAILY',
         HORIZON = 30) AS (
  training_data AS (
    SELECT order_day, revenue FROM ml.revenue_training
  ),
  custom_holiday AS (
    -- Replace each YYYY-MM-DD with the first day of that Eid, from Jordan's official announcement.
    SELECT 'jordan' AS region, 'Eid_al_Fitr' AS holiday_name, DATE 'YYYY-MM-DD' AS primary_date,  -- 2025
           1 AS preholiday_days, 3 AS postholiday_days
    UNION ALL
    SELECT 'jordan', 'Eid_al_Fitr', DATE 'YYYY-MM-DD', 1, 3  -- 2026
    UNION ALL
    SELECT 'jordan', 'Eid_al_Adha', DATE 'YYYY-MM-DD', 1, 4  -- 2025
    UNION ALL
    SELECT 'jordan', 'Eid_al_Adha', DATE 'YYYY-MM-DD', 1, 4  -- 2026
  )
);

SELECT has_holiday_effect, seasonal_periods
FROM ML.ARIMA_EVALUATE(MODEL ml.revenue_arima_eid, STRUCT(FALSE AS show_all_candidate_models));

-- Step 9 · Save 30 days for D22
CREATE OR REPLACE MODEL ml.revenue_arima_final
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'order_day',
         TIME_SERIES_DATA_COL = 'revenue',
         DATA_FREQUENCY = 'DAILY',
         HORIZON = 30) AS
SELECT order_day, revenue FROM ml.nakheel_daily
WHERE order_day < '2026-08-27';

CREATE OR REPLACE TABLE ml.revenue_forecast AS
SELECT DATE(forecast_timestamp) AS forecast_day,
       ROUND(GREATEST(forecast_value, 0), 2) AS forecast_revenue,
       ROUND(GREATEST(prediction_interval_lower_bound, 0), 2) AS lower_95,
       ROUND(prediction_interval_upper_bound, 2) AS upper_95
FROM ML.FORECAST(MODEL ml.revenue_arima_final, STRUCT(30 AS horizon, 0.95 AS confidence_level));

SELECT table_name, column_name
FROM ml.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'revenue_forecast'
  AND LOWER(table_name) = LOWER(column_name);
