-- D14 · Lab 08 · Boosted trees, option by option · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

SELECT 'default' AS model,
       ROUND(r2_score, 3) AS validation_r2, ROUND(mean_absolute_error) AS validation_mae
FROM ML.EVALUATE(MODEL ml.ins_boosted, (SELECT * FROM ml.insurance_groups WHERE split = 'validation'));

-- Step 1 · Rounds, and what training recorded
SELECT iteration, ROUND(loss) AS training_loss, eval_loss, duration_ms
FROM ML.TRAINING_INFO(MODEL ml.ins_boosted)
ORDER BY iteration;

-- Step 2 · Many rounds, no stopping
CREATE OR REPLACE MODEL ml.ins_boost_200
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         max_iterations = 200, early_stop = FALSE) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

-- Step 3 · A smaller step
CREATE OR REPLACE MODEL ml.ins_boost_slow
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         learn_rate = 0.1, max_iterations = 100) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

CREATE OR REPLACE MODEL ml.ins_boost_fast
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         learn_rate = 1.0) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

-- Step 4 · Smaller trees
CREATE OR REPLACE MODEL ml.ins_boost_d2
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         max_tree_depth = 2) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

CREATE OR REPLACE MODEL ml.ins_boost_child20
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         min_tree_child_weight = 20) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

-- Step 5 · Shrinking: L1 and L2
CREATE OR REPLACE MODEL ml.ins_boost_l2_10
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         l2_reg = 10) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

-- Step 6 · Randomness: rows, columns and parallel trees
CREATE OR REPLACE MODEL ml.ins_boost_random
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         num_parallel_tree = 4, subsample = 0.8, colsample_bynode = 0.8) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

-- Step 7 · DART: dropping trees
CREATE OR REPLACE MODEL ml.ins_boost_dart
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         booster_type = 'DART', dropout = 0.1) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';

-- Step 8 · How the trees are built, and how text becomes numbers
CREATE OR REPLACE MODEL ml.ins_boost_onehot
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR', input_label_cols = ['charges'], data_split_method = 'NO_SPLIT',
         category_encoding_method = 'ONE_HOT_ENCODING', tree_method = 'EXACT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups WHERE split = 'train';
