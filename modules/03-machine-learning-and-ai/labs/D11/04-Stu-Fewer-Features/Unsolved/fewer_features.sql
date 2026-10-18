-- D11 · 04 · Do we need all six features? · Starter
-- CREATE MODEL and the ML. functions run in BigQuery only.

-- 1. Three features: age, bmi, smoker.
CREATE OR REPLACE MODEL ml.insurance_three
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['charges'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2) AS
SELECT age, bmi, smoker, charges
FROM ml.insurance;

-- 2. One feature: age.
CREATE OR REPLACE MODEL ml.insurance_age
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['charges'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2) AS
SELECT age, charges
FROM ml.insurance;

-- 3. All three models, each scored on the rows it held aside.
SELECT 'six features' AS model, ROUND(mean_absolute_error) AS mae, ROUND(r2_score, 3) AS r2
FROM ML.EVALUATE(MODEL ml.insurance_model)
UNION ALL
SELECT 'three features', ROUND(mean_absolute_error), ROUND(r2_score, 3)
FROM ML.EVALUATE(MODEL ml.insurance_three)
UNION ALL
SELECT 'age only', ROUND(mean_absolute_error), ROUND(r2_score, 3)
FROM ML.EVALUATE(MODEL ml.insurance_age);

-- Bonus. smoker alone.
CREATE OR REPLACE MODEL ml.insurance_smoker
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['charges'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2) AS
SELECT smoker, charges
FROM ml.insurance;

SELECT ROUND(mean_absolute_error) AS mae, ROUND(r2_score, 3) AS r2
FROM ML.EVALUATE(MODEL ml.insurance_smoker);
