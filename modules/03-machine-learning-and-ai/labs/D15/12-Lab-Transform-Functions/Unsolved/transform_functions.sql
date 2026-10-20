-- D15 · Lab 12 · TRANSFORM and the preprocessing functions · Starter
-- Self-guided: run one statement at a time, after reading its step in the README.
-- The README explains each step: read it first, run the SQL, then compare with "What you should see".

-- Step 1 · The leak, in numbers
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

-- Step 2 · What ML.QUANTILE_BUCKETIZE returns on its own
SELECT bmi_quarter, MIN(bmi) AS lowest, MAX(bmi) AS highest, COUNT(*) AS people
FROM (
  SELECT bmi, ML.QUANTILE_BUCKETIZE(bmi, 4, 'bucket_ranges') OVER () AS bmi_quarter
  FROM ml.insurance_groups
  WHERE split = 'train'
)
GROUP BY bmi_quarter
ORDER BY lowest;

-- Step 3 · Inside TRANSFORM, and what the model sees
SELECT bmi_band, COUNT(*) AS people
FROM ML.TRANSFORM(MODEL ml.ins_transform,
  (SELECT * FROM ml.insurance_groups WHERE split = 'validation'))
GROUP BY bmi_band
ORDER BY bmi_band;

WITH cuts_train AS (
  SELECT DISTINCT PERCENTILE_CONT(bmi, 0.25) OVER () AS c1,
         PERCENTILE_CONT(bmi, 0.5) OVER () AS c2,
         PERCENTILE_CONT(bmi, 0.75) OVER () AS c3
  FROM ml.insurance_groups
  WHERE split = 'train'
)
SELECT CONCAT('bin_', CAST(1 + IF(g.bmi >= t.c1, 1, 0) + IF(g.bmi >= t.c2, 1, 0) + IF(g.bmi >= t.c3, 1, 0) AS STRING)) AS bmi_band,
       COUNT(*) AS people
FROM ml.insurance_groups AS g
CROSS JOIN cuts_train AS t
WHERE g.split = 'validation'
GROUP BY bmi_band
ORDER BY bmi_band;

-- Step 4 · The leaky way, for comparison
CREATE OR REPLACE VIEW ml.insurance_banded_all AS
SELECT *, ML.QUANTILE_BUCKETIZE(bmi, 4) OVER () AS bmi_band
FROM ml.insurance_groups;

CREATE OR REPLACE MODEL ml.ins_leaky_band
OPTIONS (model_type = 'LINEAR_REG',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT bmi_band, age, sex, children, smoker, region, charges
FROM ml.insurance_banded_all
WHERE split = 'train';

SELECT 'bands over all rows (leaky)' AS model,
       ROUND(r2_score, 3) AS validation_r2, ROUND(mean_absolute_error) AS validation_mae
FROM ML.EVALUATE(MODEL ml.ins_leaky_band,
  (SELECT * FROM ml.insurance_banded_all WHERE split = 'validation'))
UNION ALL
SELECT 'bands from training rows (TRANSFORM)',
       ROUND(r2_score, 3), ROUND(mean_absolute_error)
FROM ML.EVALUATE(MODEL ml.ins_transform,
  (SELECT * FROM ml.insurance_groups WHERE split = 'validation'));

-- Step 5 · ML.BUCKETIZE: cut points you choose
SELECT ML.BUCKETIZE(2.5, [1, 2, 3]) AS default_names,
       ML.BUCKETIZE(2.5, [1, 2, 3], TRUE) AS without_outer_buckets,
       ML.BUCKETIZE(2.5, [1, 2, 3], FALSE, 'bucket_ranges') AS as_range;

CREATE OR REPLACE MODEL ml.ins_fixed_bands
TRANSFORM (ML.BUCKETIZE(age, [30, 45, 60]) AS age_band,
           ML.BUCKETIZE(bmi, [30]) AS bmi_30,
           sex, children, smoker, region, charges)
OPTIONS (model_type = 'LINEAR_REG',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

SELECT CASE WHEN age < 30 THEN 'bin_1' WHEN age < 45 THEN 'bin_2' WHEN age < 60 THEN 'bin_3' ELSE 'bin_4' END AS age_band,
       COUNT(*) AS people
FROM ml.insurance_groups
WHERE split = 'train'
GROUP BY age_band
ORDER BY age_band;

-- Step 6 · The scalers
CREATE OR REPLACE MODEL ml.ins_scaled
TRANSFORM (ML.STANDARD_SCALER(bmi) OVER () AS bmi_standard,
           ML.MIN_MAX_SCALER(age) OVER () AS age_min_max,
           ML.MAX_ABS_SCALER(children) OVER () AS children_max_abs,
           sex, smoker, region, charges)
OPTIONS (model_type = 'LINEAR_REG',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

SELECT 'train' AS rows_scaled,
       ROUND(AVG(bmi_standard), 3) AS avg_bmi_standard,
       ROUND(MIN(age_min_max), 3) AS min_age_scaled, ROUND(MAX(age_min_max), 3) AS max_age_scaled
FROM ML.TRANSFORM(MODEL ml.ins_scaled,
  (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
UNION ALL
SELECT 'validation',
       ROUND(AVG(bmi_standard), 3), ROUND(MIN(age_min_max), 3), ROUND(MAX(age_min_max), 3)
FROM ML.TRANSFORM(MODEL ml.ins_scaled,
  (SELECT * FROM ml.insurance_groups WHERE split = 'validation'));

SELECT split, ROUND(AVG(bmi), 2) AS avg_bmi, MIN(age) AS youngest, MAX(age) AS oldest
FROM ml.insurance_groups
GROUP BY split
ORDER BY split;

-- Step 7 · Crosses and powers
CREATE OR REPLACE MODEL ml.ins_cross_poly
TRANSFORM (ML.FEATURE_CROSS(STRUCT(smoker, region)) AS smoker_region,
           ML.POLYNOMIAL_EXPAND(STRUCT(age, bmi), 2) AS age_bmi_poly,
           sex, children, smoker, charges)
OPTIONS (model_type = 'LINEAR_REG',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

SELECT *
FROM ML.TRANSFORM(MODEL ml.ins_cross_poly,
  (SELECT * FROM ml.insurance_groups WHERE split = 'validation'))
LIMIT 3;

-- Step 10 · ML.FEATURE_INFO: the columns before the transform
SELECT input, min, max, ROUND(mean, 2) AS mean, median, category_count, null_count
FROM ML.FEATURE_INFO(MODEL ml.ins_scaled);

SELECT *
FROM ML.TRANSFORM(MODEL ml.ins_scaled,
  (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
LIMIT 3;

SELECT 'age' AS input, MIN(age) AS min_value, MAX(age) AS max_value, ROUND(AVG(age), 2) AS mean_value,
       NULL AS categories
FROM ml.insurance_groups WHERE split = 'train'
UNION ALL
SELECT 'bmi', MIN(bmi), MAX(bmi), ROUND(AVG(bmi), 2), NULL
FROM ml.insurance_groups WHERE split = 'train'
UNION ALL
SELECT 'children', MIN(children), MAX(children), ROUND(AVG(children), 2), NULL
FROM ml.insurance_groups WHERE split = 'train'
UNION ALL
SELECT 'sex', NULL, NULL, NULL, COUNT(DISTINCT sex)
FROM ml.insurance_groups WHERE split = 'train'
UNION ALL
SELECT 'smoker', NULL, NULL, NULL, COUNT(DISTINCT smoker)
FROM ml.insurance_groups WHERE split = 'train'
UNION ALL
SELECT 'region', NULL, NULL, NULL, COUNT(DISTINCT region)
FROM ml.insurance_groups WHERE split = 'train';
