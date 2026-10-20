-- D15 · Split by date, and two simple forecasts · Starter
-- Run one statement at a time, in order. CREATE MODEL and the ML. functions run in BigQuery only.
-- Fill in each ____ as the README asks, then run the statement.

-- Step 1 · The validation and test months
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

-- Step 2 · The naive forecast: last month, held flat
SELECT month, passengers
FROM ml.air_training
ORDER BY month DESC
LIMIT 1;

SELECT ROUND(AVG(ABS(v.passengers - ____)), 1) AS mae_naive,
       ROUND(100 * AVG(ABS(v.passengers - ____) / v.passengers), 1) AS mape_naive
FROM ml.air_validation AS v;

-- Step 3 · The seasonal naive forecast: same month, one year earlier
SELECT ROUND(AVG(ABS(v.passengers - t.passengers)), 1) AS mae_seasonal_naive,
       ROUND(100 * AVG(ABS(v.passengers - t.passengers) / v.passengers), 1) AS mape_seasonal_naive
FROM ml.air_validation AS v
JOIN ml.air_training AS t
  ON t.month = ____;

-- Step 4 · The training mean, held flat
SELECT ROUND(AVG(ABS(v.passengers - (SELECT ____ FROM ml.air_training))), 1) AS mae_training_mean,
       ROUND(100 * AVG(ABS(v.passengers - (SELECT ____ FROM ml.air_training)) / v.passengers), 1) AS mape_training_mean
FROM ml.air_validation AS v;

-- Bonus
SELECT DISTINCT PERCENTILE_CONT(passengers, 0.5) OVER () AS training_median
FROM ml.air_training;
