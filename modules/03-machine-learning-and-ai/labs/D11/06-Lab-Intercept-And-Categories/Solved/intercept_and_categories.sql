-- D11 · Lab 06 · The intercept, text features, and reading weights · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time and compare with the README's 'What you should see'.

-- Step 1 · `FIT_INTERCEPT`: does the line need a starting point?
CREATE OR REPLACE MODEL ml.salary_no_intercept
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['salary'],
         fit_intercept = FALSE) AS
SELECT years_experience, salary
FROM ml.salary;

SELECT processed_input, ROUND(weight, 1) AS weight
FROM ML.WEIGHTS(MODEL ml.salary_no_intercept);

SELECT ROUND(mean_absolute_error) AS mae, ROUND(r2_score, 3) AS r2
FROM ML.EVALUATE(MODEL ml.salary_no_intercept);

-- Step 2 · `CATEGORY_ENCODING_METHOD`: how text becomes numbers
CREATE OR REPLACE MODEL ml.insurance_onehot
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['charges'],
         category_encoding_method = 'ONE_HOT_ENCODING') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance;

CREATE OR REPLACE MODEL ml.insurance_dummy
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['charges'],
         category_encoding_method = 'DUMMY_ENCODING') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance;

SELECT 'one-hot' AS encoding, cw.category, ROUND(cw.weight, 1) AS weight
FROM ML.WEIGHTS(MODEL ml.insurance_onehot), UNNEST(category_weights) AS cw
WHERE processed_input = 'region'
UNION ALL
SELECT 'dummy', cw.category, ROUND(cw.weight, 1)
FROM ML.WEIGHTS(MODEL ml.insurance_dummy), UNNEST(category_weights) AS cw
WHERE processed_input = 'region'
ORDER BY encoding, category;

-- Step 3 · `CALCULATE_P_VALUES`: which weights would survive new data?
CREATE OR REPLACE MODEL ml.insurance_pvalues
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['charges'],
         category_encoding_method = 'DUMMY_ENCODING',
         calculate_p_values = TRUE,
         data_split_method = 'NO_SPLIT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance;

SELECT processed_input, category, ROUND(weight, 1) AS weight,
       ROUND(standard_error, 1) AS standard_error, ROUND(p_value, 4) AS p_value
FROM ML.ADVANCED_WEIGHTS(MODEL ml.insurance_pvalues, STRUCT(FALSE AS standardize));

-- Step 4 · Raw weights against standardized weights
SELECT processed_input, ROUND(weight, 4) AS weight
FROM ML.WEIGHTS(MODEL ml.cars_random)
WHERE processed_input != '__INTERCEPT__'
ORDER BY ABS(weight) DESC;

SELECT processed_input, ROUND(weight, 2) AS weight
FROM ML.WEIGHTS(MODEL ml.cars_random, STRUCT(TRUE AS standardize))
WHERE processed_input != '__INTERCEPT__'
ORDER BY ABS(weight) DESC;

-- Step 5 · `ENABLE_GLOBAL_EXPLAIN`: which features matter most, in one table
CREATE OR REPLACE MODEL ml.insurance_explained
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['charges'],
         enable_global_explain = TRUE) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance;

SELECT feature, ROUND(attribution, 1) AS attribution
FROM ML.GLOBAL_EXPLAIN(MODEL ml.insurance_explained)
ORDER BY attribution DESC;

