-- D14 · 03 · One tree, grown too deep · Starter
-- Run one numbered block at a time. CREATE MODEL and the ML. functions run in BigQuery only.
-- You need the view ml.insurance_groups from activity 01, block 1.

-- 1. One tree, at most three questions deep.
--    BigQuery has no single-tree model type, so we ask the boosted-trees model for one tree, kept whole.
CREATE OR REPLACE MODEL ml.ins_tree3
OPTIONS (
  model_type = 'BOOSTED_TREE_REGRESSOR',
  input_label_cols = ['charges'],
  data_split_method = 'NO_SPLIT',
  max_iterations = 1,    -- one round of boosting: one tree
  learn_rate = 1,        -- keep the whole tree, not a share of it
  l2_reg = 0,            -- no shrinking: each leaf predicts the average of its training rows
  max_tree_depth = 3     -- at most three questions on any path
) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

-- 2. The same tree, allowed fifteen questions deep.
CREATE OR REPLACE MODEL ml.ins_tree15
OPTIONS (
  model_type = 'BOOSTED_TREE_REGRESSOR',
  input_label_cols = ['charges'],
  data_split_method = 'NO_SPLIT',
  max_iterations = 1,
  learn_rate = 1,
  l2_reg = 0,
  max_tree_depth = 15
) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

-- 3. Each tree scored twice: on the rows it learned from, and on the validation rows it never saw.
SELECT 'depth 3' AS tree, 'training (seen)' AS scored_on,
       ROUND(r2_score, 2) AS r2, ROUND(mean_absolute_error) AS mae
FROM ML.EVALUATE(MODEL ml.ins_tree3, (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
UNION ALL
SELECT 'depth 3', 'validation (unseen)', ROUND(r2_score, 2), ROUND(mean_absolute_error)
FROM ML.EVALUATE(MODEL ml.ins_tree3, (SELECT * FROM ml.insurance_groups WHERE split = 'validation'))
UNION ALL
SELECT 'depth 15', 'training (seen)', ROUND(r2_score, 2), ROUND(mean_absolute_error)
FROM ML.EVALUATE(MODEL ml.ins_tree15, (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
UNION ALL
SELECT 'depth 15', 'validation (unseen)', ROUND(r2_score, 2), ROUND(mean_absolute_error)
FROM ML.EVALUATE(MODEL ml.ins_tree15, (SELECT * FROM ml.insurance_groups WHERE split = 'validation'));

-- 4. How many different answers can each tree give? Count the distinct predictions on the training rows.
SELECT 'depth 3' AS tree, COUNT(DISTINCT ROUND(predicted_charges, 2)) AS different_predictions
FROM ML.PREDICT(MODEL ml.ins_tree3, (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
UNION ALL
SELECT 'depth 15', COUNT(DISTINCT ROUND(predicted_charges, 2))
FROM ML.PREDICT(MODEL ml.ins_tree15, (SELECT * FROM ml.insurance_groups WHERE split = 'train'));
