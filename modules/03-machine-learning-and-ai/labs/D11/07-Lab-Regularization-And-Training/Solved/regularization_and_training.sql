-- D11 · Lab 07 · Holding the weights back, and how training runs · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time and compare with the README's 'What you should see'.

-- Step 1 · `OPTIMIZE_STRATEGY`: one calculation, or many small steps
CREATE OR REPLACE MODEL ml.cars_normal
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         optimize_strategy = 'NORMAL_EQUATION') AS
SELECT * FROM ml.cars_clean;

CREATE OR REPLACE MODEL ml.cars_steps
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         optimize_strategy = 'BATCH_GRADIENT_DESCENT') AS
SELECT * FROM ml.cars_clean;

SELECT iteration, ROUND(loss, 2) AS loss, ROUND(eval_loss, 2) AS eval_loss,
       ROUND(learning_rate, 3) AS learning_rate
FROM ML.TRAINING_INFO(MODEL ml.cars_steps)
ORDER BY iteration;

-- Step 2 · `MAX_ITERATIONS`, `EARLY_STOP` and `MIN_REL_PROGRESS`: when to stop
CREATE OR REPLACE MODEL ml.cars_two_steps
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         optimize_strategy = 'BATCH_GRADIENT_DESCENT', max_iterations = 2) AS
SELECT * FROM ml.cars_clean;

SELECT 'two steps' AS model, ROUND(mean_absolute_error, 2) AS mae, ROUND(r2_score, 3) AS r2
FROM ML.EVALUATE(MODEL ml.cars_two_steps)
UNION ALL
SELECT 'until it stopped', ROUND(mean_absolute_error, 2), ROUND(r2_score, 3)
FROM ML.EVALUATE(MODEL ml.cars_steps);

CREATE OR REPLACE MODEL ml.cars_two_steps
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         optimize_strategy = 'BATCH_GRADIENT_DESCENT', max_iterations = 2,
         warm_start = TRUE) AS
SELECT * FROM ml.cars_clean;

SELECT training_run, iteration, ROUND(loss, 2) AS loss
FROM ML.TRAINING_INFO(MODEL ml.cars_two_steps)
ORDER BY training_run, iteration;

-- Step 3 · `LEARN_RATE_STRATEGY` and `LEARN_RATE`: how big each step is
CREATE OR REPLACE MODEL ml.cars_tiny_steps
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         optimize_strategy = 'BATCH_GRADIENT_DESCENT',
         learn_rate_strategy = 'CONSTANT', learn_rate = 0.001) AS
SELECT * FROM ml.cars_clean;

SELECT iteration, ROUND(loss, 2) AS loss, ROUND(eval_loss, 2) AS eval_loss
FROM ML.TRAINING_INFO(MODEL ml.cars_tiny_steps)
ORDER BY iteration;

-- Step 4 · Why hold weights back at all?
SELECT ROUND(CORR(displacement, weight), 2) AS displacement_weight,
       ROUND(CORR(displacement, cylinders), 2) AS displacement_cylinders,
       ROUND(CORR(horsepower, weight), 2) AS horsepower_weight
FROM ml.cars_clean;

-- Step 5 · `L2_REG`: shrink every weight a little
CREATE OR REPLACE MODEL ml.cars_l2
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         l2_reg = 50) AS
SELECT * FROM ml.cars_clean;

SELECT 'no penalty' AS model, processed_input, ROUND(weight, 2) AS weight
FROM ML.WEIGHTS(MODEL ml.cars_normal, STRUCT(TRUE AS standardize))
UNION ALL
SELECT 'L2 = 50', processed_input, ROUND(weight, 2)
FROM ML.WEIGHTS(MODEL ml.cars_l2, STRUCT(TRUE AS standardize))
ORDER BY processed_input, model;

-- Step 6 · `L1_REG`: push weak weights to exactly zero
CREATE OR REPLACE MODEL ml.cars_l1
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         l1_reg = 50) AS
SELECT * FROM ml.cars_clean;

SELECT processed_input, ROUND(weight, 3) AS weight
FROM ML.WEIGHTS(MODEL ml.cars_l1, STRUCT(TRUE AS standardize))
ORDER BY ABS(weight) DESC;

-- Part C (stretch) · Let BigQuery try the settings for you: hyperparameter tuning
CREATE OR REPLACE MODEL ml.cars_tuned
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         num_trials = 10, max_parallel_trials = 2,
         hparam_tuning_algorithm = 'VIZIER_DEFAULT',
         hparam_tuning_objectives = ['R2_SCORE'],
         l1_reg = HPARAM_RANGE(0, 20),
         l2_reg = HPARAM_RANGE(0, 20),
         data_split_method = 'RANDOM',
         data_split_eval_fraction = 0.2,
         data_split_test_fraction = 0.2) AS
SELECT * FROM ml.cars_clean;

SELECT trial_id, hyperparameters, hparam_tuning_evaluation_metrics, is_optimal
FROM ML.TRIAL_INFO(MODEL ml.cars_tuned)
ORDER BY trial_id;

