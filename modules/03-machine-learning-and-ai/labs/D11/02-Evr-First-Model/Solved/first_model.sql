-- D11 · 02 · Your first model: a salary from years of experience · Solved
-- Run one numbered block at a time. CREATE MODEL and the ML. functions run in BigQuery only.

-- 1. A dataset for machine learning, in the same location as nakheel.
CREATE SCHEMA IF NOT EXISTS ml OPTIONS (location = 'US');

-- (Upload salary_data.csv as the table ml.salary_data: see the README, step 2.)

-- 2. Look at the data first. One row is one past hire.
SELECT years_experience, salary
FROM ml.salary_data
ORDER BY years_experience;

-- 3. Train. The label is salary; every other column in the SELECT is a feature.
CREATE OR REPLACE MODEL ml.salary_model
OPTIONS (
  model_type = 'LINEAR_REG',
  input_label_cols = ['salary']
) AS
SELECT years_experience, salary
FROM ml.salary_data;

-- 4. The model is two numbers: a starting point and an amount per year.
SELECT processed_input, ROUND(weight, 1) AS weight
FROM ML.WEIGHTS(MODEL ml.salary_model);

-- 5. A new candidate with 5 years of experience.
SELECT years_experience, ROUND(predicted_salary) AS predicted_salary
FROM ML.PREDICT(MODEL ml.salary_model,
  (SELECT 5.0 AS years_experience));

-- 6. Later in class: how good is it?
SELECT ROUND(mean_absolute_error) AS mae,
       ROUND(r2_score, 3) AS r2
FROM ML.EVALUATE(MODEL ml.salary_model);
