-- D15 · 03 · Split by date, and two simple forecasts · Solved
-- Run one statement at a time. Everything here is plain SQL: no model is involved.
-- You need ml.air_training (activity 02, step 1).

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

-- The subquery finds December 1958 (337) instead of typing the number.
SELECT ROUND(AVG(ABS(v.passengers -
         (SELECT passengers FROM ml.air_training ORDER BY month DESC LIMIT 1))), 1) AS mae_naive,
       ROUND(100 * AVG(ABS(v.passengers -
         (SELECT passengers FROM ml.air_training ORDER BY month DESC LIMIT 1)) / v.passengers), 1) AS mape_naive
FROM ml.air_validation AS v;

-- Step 3 · The seasonal naive forecast: same month, one year earlier
SELECT ROUND(AVG(ABS(v.passengers - t.passengers)), 1) AS mae_seasonal_naive,
       ROUND(100 * AVG(ABS(v.passengers - t.passengers) / v.passengers), 1) AS mape_seasonal_naive
FROM ml.air_validation AS v
JOIN ml.air_training AS t
  ON t.month = DATE_SUB(v.month, INTERVAL 1 YEAR);

-- Step 4 · The training mean, held flat
SELECT ROUND(AVG(ABS(v.passengers - (SELECT AVG(passengers) FROM ml.air_training))), 1) AS mae_training_mean,
       ROUND(100 * AVG(ABS(v.passengers - (SELECT AVG(passengers) FROM ml.air_training)) / v.passengers), 1) AS mape_training_mean
FROM ml.air_validation AS v;

-- Step 5 · The scoreboard: all three MAEs in one query
SELECT
  ROUND(AVG(ABS(v.passengers -
    (SELECT passengers FROM ml.air_training ORDER BY month DESC LIMIT 1))), 1) AS mae_naive,
  ROUND(AVG(ABS(v.passengers - t.passengers)), 1) AS mae_seasonal_naive,
  ROUND(AVG(ABS(v.passengers -
    (SELECT AVG(passengers) FROM ml.air_training))), 1) AS mae_training_mean
FROM ml.air_validation AS v
JOIN ml.air_training AS t
  ON t.month = DATE_SUB(v.month, INTERVAL 1 YEAR);
-- Seasonal naive 47.3 < naive 91.3 < training mean 182.4: the seasonal naive is the bar to beat.
-- It knows about summer, so it halves the naive's miss. Every 1959 month is above the same month
-- of 1958 (every miss is positive): the series keeps growing, and the seasonal naive does not know that.

-- Bonus · The training median
SELECT DISTINCT PERCENTILE_CONT(passengers, 0.5) OVER () AS training_median
FROM ml.air_training;

SELECT ROUND(AVG(ABS(v.passengers - 233.5)), 1) AS mae_training_median,
       ROUND(100 * AVG(ABS(v.passengers - 233.5) / v.passengers), 1) AS mape_training_median
FROM ml.air_validation AS v;
