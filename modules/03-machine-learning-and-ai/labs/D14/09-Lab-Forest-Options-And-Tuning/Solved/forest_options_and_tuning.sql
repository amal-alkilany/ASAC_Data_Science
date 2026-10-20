-- D14 · Lab 09 · Random forests, option by option, then letting BigQuery tune · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

SELECT ROUND(r2_score, 3) AS validation_r2, ROUND(mean_absolute_error) AS validation_mae
FROM ML.EVALUATE(MODEL ml.ins_forest, (SELECT * FROM ml.insurance_groups WHERE split = 'validation'));

-- Step 1 · How many trees
CREATE OR REPLACE MODEL ml.ins_forest_2
OPTIONS (model_type = 'RANDOM_FOREST_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         num_parallel_tree = 2) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

CREATE OR REPLACE MODEL ml.ins_forest_300
OPTIONS (model_type = 'RANDOM_FOREST_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         num_parallel_tree = 300) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

-- Step 2 · How deep
CREATE OR REPLACE MODEL ml.ins_forest_d6
OPTIONS (model_type = 'RANDOM_FOREST_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         max_tree_depth = 6) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

-- Step 3 · The two random draws
CREATE OR REPLACE MODEL ml.ins_forest_cols50
OPTIONS (model_type = 'RANDOM_FOREST_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         colsample_bynode = 0.5) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

-- Step 4 · Tell BigQuery which rows are which
CREATE OR REPLACE VIEW ml.insurance_tuning AS
SELECT * EXCEPT (split),
       CASE split WHEN 'train' THEN 'TRAIN' WHEN 'validation' THEN 'EVAL' ELSE 'TEST' END AS tuning_group
FROM ml.insurance_groups;

SELECT tuning_group, COUNT(*) AS people
FROM ml.insurance_tuning
GROUP BY tuning_group;

-- Step 5 · Ten trials
CREATE OR REPLACE MODEL ml.ins_boost_tuned
OPTIONS (
  model_type = 'BOOSTED_TREE_REGRESSOR',
  input_label_cols = ['charges'],
  data_split_method = 'CUSTOM',
  data_split_col = 'tuning_group',
  num_trials = 10,
  max_parallel_trials = 2,
  learn_rate = HPARAM_RANGE(0.05, 0.5),
  max_tree_depth = HPARAM_CANDIDATES([2, 3, 4, 6]),
  hparam_tuning_objectives = ['R2_SCORE']
) AS
SELECT age, sex, bmi, children, smoker, region, charges, tuning_group
FROM ml.insurance_tuning;

-- Step 6 · Read the trials
SELECT trial_id,
       ROUND(hyperparameters.learn_rate, 3) AS learn_rate,
       hyperparameters.max_tree_depth AS max_tree_depth,
       ROUND(hparam_tuning_evaluation_metrics.r2_score, 3) AS eval_r2,
       status, is_optimal
FROM ML.TRIAL_INFO(MODEL ml.ins_boost_tuned)
ORDER BY eval_r2 DESC;
