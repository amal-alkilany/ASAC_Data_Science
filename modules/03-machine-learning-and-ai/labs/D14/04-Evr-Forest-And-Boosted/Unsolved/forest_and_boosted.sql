-- D14 · 04 · A forest and boosted trees, on the same rows · Starter
-- Run one numbered block at a time. CREATE MODEL and the ML. functions run in BigQuery only.
-- You need ml.insurance_groups, ml.ins_linear and ml.ins_boosted (activity 01) and ml.ins_tree3, ml.ins_tree15 (activity 03).

-- 1. A random forest, with BigQuery's defaults written out:
--    100 trees, each up to 15 questions deep, each grown on 80% of the training rows,
--    choosing among 80% of the columns at every question.
CREATE OR REPLACE MODEL ml.ins_forest
OPTIONS (
  model_type = 'RANDOM_FOREST_REGRESSOR',
  input_label_cols = ['charges'],
  data_split_method = 'NO_SPLIT',
  num_parallel_tree = 100,
  max_tree_depth = 15,
  subsample = 0.8,
  colsample_bynode = 0.8
) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

-- 2. Every model so far, on the same 268 validation people.
SELECT 'linear' AS model, ROUND(mean_absolute_error) AS mae, ROUND(r2_score, 2) AS r2
FROM ML.EVALUATE(MODEL ml.ins_linear, (SELECT * FROM ml.insurance_groups WHERE split = 'validation'))
UNION ALL
SELECT 'one tree, depth 15', ROUND(mean_absolute_error), ROUND(r2_score, 2)
FROM ML.EVALUATE(MODEL ml.ins_tree15, (SELECT * FROM ml.insurance_groups WHERE split = 'validation'))
UNION ALL
SELECT 'one tree, depth 3', ROUND(mean_absolute_error), ROUND(r2_score, 2)
FROM ML.EVALUATE(MODEL ml.ins_tree3, (SELECT * FROM ml.insurance_groups WHERE split = 'validation'))
UNION ALL
SELECT 'random forest', ROUND(mean_absolute_error), ROUND(r2_score, 2)
FROM ML.EVALUATE(MODEL ml.ins_forest, (SELECT * FROM ml.insurance_groups WHERE split = 'validation'))
UNION ALL
SELECT 'boosted trees', ROUND(mean_absolute_error), ROUND(r2_score, 2)
FROM ML.EVALUATE(MODEL ml.ins_boosted, (SELECT * FROM ml.insurance_groups WHERE split = 'validation'))
ORDER BY r2 DESC;

-- 3. The same models on the rows they learned from. A big gap between this and block 2 is overfitting.
SELECT 'linear' AS model, ROUND(r2_score, 2) AS training_r2
FROM ML.EVALUATE(MODEL ml.ins_linear, (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
UNION ALL
SELECT 'one tree, depth 15', ROUND(r2_score, 2)
FROM ML.EVALUATE(MODEL ml.ins_tree15, (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
UNION ALL
SELECT 'one tree, depth 3', ROUND(r2_score, 2)
FROM ML.EVALUATE(MODEL ml.ins_tree3, (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
UNION ALL
SELECT 'random forest', ROUND(r2_score, 2)
FROM ML.EVALUATE(MODEL ml.ins_forest, (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
UNION ALL
SELECT 'boosted trees', ROUND(r2_score, 2)
FROM ML.EVALUATE(MODEL ml.ins_boosted, (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
ORDER BY training_r2 DESC;

-- 4. Which columns did the boosted trees use?
--    importance_weight: how many questions used the column. importance_gain: how much each of them helped, on average.
--    weight x gain is the column's total gain; share_of_gain is its share of all columns' total.
SELECT feature,
       importance_weight,
       ROUND(importance_weight * importance_gain
             / SUM(importance_weight * importance_gain) OVER (), 3) AS share_of_gain
FROM ML.FEATURE_IMPORTANCE(MODEL ml.ins_boosted)
ORDER BY share_of_gain DESC;
