-- D15 · Fix the leak with TRANSFORM, then save predictions for Power BI · Solved (every query from the README, in order)
-- Run one statement at a time, in order. CREATE MODEL and the ML. functions run in BigQuery only.

-- Step 1 · The leak, and TRANSFORM
SELECT DISTINCT 'all 1,338 people' AS rows_used,
       ROUND(PERCENTILE_CONT(bmi, 0.25) OVER (), 2) AS cut_1,
       ROUND(PERCENTILE_CONT(bmi, 0.5) OVER (), 2) AS cut_2,
       ROUND(PERCENTILE_CONT(bmi, 0.75) OVER (), 2) AS cut_3
FROM ml.insurance_groups
UNION ALL
SELECT DISTINCT 'the 803 training people',
       ROUND(PERCENTILE_CONT(bmi, 0.25) OVER (), 2),
       ROUND(PERCENTILE_CONT(bmi, 0.5) OVER (), 2),
       ROUND(PERCENTILE_CONT(bmi, 0.75) OVER (), 2)
FROM ml.insurance_groups
WHERE split = 'train';

WITH cuts_all AS (
  SELECT DISTINCT PERCENTILE_CONT(bmi, 0.25) OVER () AS c1,
         PERCENTILE_CONT(bmi, 0.5) OVER () AS c2,
         PERCENTILE_CONT(bmi, 0.75) OVER () AS c3
  FROM ml.insurance_groups
),
cuts_train AS (
  SELECT DISTINCT PERCENTILE_CONT(bmi, 0.25) OVER () AS c1,
         PERCENTILE_CONT(bmi, 0.5) OVER () AS c2,
         PERCENTILE_CONT(bmi, 0.75) OVER () AS c3
  FROM ml.insurance_groups
  WHERE split = 'train'
)
SELECT g.split,
       COUNTIF(IF(g.bmi >= a.c1, 1, 0) + IF(g.bmi >= a.c2, 1, 0) + IF(g.bmi >= a.c3, 1, 0)
            != IF(g.bmi >= t.c1, 1, 0) + IF(g.bmi >= t.c2, 1, 0) + IF(g.bmi >= t.c3, 1, 0)) AS people_changing_band
FROM ml.insurance_groups AS g
CROSS JOIN cuts_all AS a
CROSS JOIN cuts_train AS t
GROUP BY g.split
ORDER BY g.split;

CREATE OR REPLACE MODEL ml.ins_transform
TRANSFORM (ML.QUANTILE_BUCKETIZE(bmi, 4) OVER () AS bmi_band,
           age, sex, children, smoker, region, charges)
OPTIONS (model_type = 'LINEAR_REG',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

-- Step 2 · Save the forecast
CREATE OR REPLACE TABLE ml.air_forecast AS
SELECT DATE(f.forecast_timestamp) AS month,
       ROUND(f.forecast_value, 1) AS forecast_passengers,
       ROUND(f.prediction_interval_lower_bound, 1) AS lower_95,
       ROUND(f.prediction_interval_upper_bound, 1) AS upper_95,
       te.passengers AS actual_passengers
FROM ML.FORECAST(MODEL ml.air_arima_final,
                 STRUCT(12 AS horizon, 0.95 AS confidence_level)) AS f
LEFT JOIN ml.air_test AS te ON te.month = DATE(f.forecast_timestamp);

-- Step 3 · Save the scored people
CREATE OR REPLACE TABLE ml.insurance_scored AS
SELECT age, sex, bmi, children, smoker, region, charges, split,
       ROUND(predicted_charges, 2) AS predicted_charges
FROM ML.PREDICT(MODEL ml.ins_transform,
  (SELECT * FROM ml.insurance_groups));

-- Step 4 · Check the names
SELECT table_name, column_name
FROM ml.INFORMATION_SCHEMA.COLUMNS
WHERE table_name IN ('air_forecast', 'insurance_scored')
  AND LOWER(table_name) = LOWER(column_name);
