# Lab 07 · Holding the weights back, and how training runs

In this self-guided lab, you will watch how BigQuery fits a line (in one calculation, or step by step), see what the learning rate and the number of steps do, and use L1 and L2 regularization to hold large weights back.

**When:** after class, about 45 minutes, at your own pace. Not submitted. · **Data:** `ml.cars_clean` (lab 05) · **SQL:** `Solved/regularization_and_training.sql`

## How to work through this lab

Run each query, compare with **What you should see**, and answer **Think** in one line. Every option is on Google's page [The CREATE MODEL statement for generalized linear models](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-glm). If `ml.cars_clean` does not exist, run step 1 of lab 05 first.

Every model in this lab uses the same split (`RANDOM`, 0.2) and the same five features, so the only thing that changes is the option you are looking at.

## Part A · How training runs

### Step 1 · `OPTIMIZE_STRATEGY`: one calculation, or many small steps

For a straight line there are two ways to find the best weights:

- **`NORMAL_EQUATION`** solves for them in one calculation. Exact and fast when there are few features.
- **`BATCH_GRADIENT_DESCENT`** starts from a guess and improves it in steps (iterations). Each step looks at the errors on all training rows and moves every weight a little in the direction that shrinks them. It is how most machine-learning models train, and the only way when there are very many features.

The default, `AUTO_STRATEGY`, picks for you. Train both on purpose:

```sql
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
```

`ML.TRAINING_INFO` shows each training step: the iteration, the `loss` on the training rows (mean squared error), the `eval_loss` on the rows held aside, and the learning rate used.

```sql
SELECT iteration, ROUND(loss, 2) AS loss, ROUND(eval_loss, 2) AS eval_loss,
       ROUND(learning_rate, 3) AS learning_rate
FROM ML.TRAINING_INFO(MODEL ml.cars_steps)
ORDER BY iteration;
```

**What you should see:** for `cars_steps`, several rows: the loss starts high and falls quickly, then flattens. Run the same query on `cars_normal`: one row.

Compare the two scores with `ML.EVALUATE`. **What you should see:** nearly the same MAE and R² (about 3.3 and 0.7). Two routes, the same line.

**Think:** looking at the loss column, when would you stop taking steps?

### Step 2 · `MAX_ITERATIONS`, `EARLY_STOP` and `MIN_REL_PROGRESS`: when to stop

Gradient descent stops for one of two reasons: it reached `MAX_ITERATIONS` (default 20), or `EARLY_STOP` (default TRUE) saw that the last step improved the loss by less than `MIN_REL_PROGRESS` (default 0.01, that is 1%). Stop it early on purpose:

```sql
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
```

**What you should see:** after two steps the model is worse: a higher MAE and a lower R². It has not finished learning. This is **underfitting**: too simple, or not trained enough, to capture the pattern. Count the rows of `ML.TRAINING_INFO(MODEL ml.cars_steps)`: that is where early stopping ended it.

**Think:** overfitting is learning the training rows too closely. What is underfitting, in your words?

**`WARM_START`: carry on from where training stopped.** Retrain the same model name with `warm_start = TRUE`, and gradient descent starts from the weights it already has instead of from scratch:

```sql
CREATE OR REPLACE MODEL ml.cars_two_steps
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         optimize_strategy = 'BATCH_GRADIENT_DESCENT', max_iterations = 2,
         warm_start = TRUE) AS
SELECT * FROM ml.cars_clean;

SELECT training_run, iteration, ROUND(loss, 2) AS loss
FROM ML.TRAINING_INFO(MODEL ml.cars_two_steps)
ORDER BY training_run, iteration;
```

**What you should see:** a second `training_run` whose loss starts where the first one ended, not back at the top. Useful when new rows arrive and you want to update a large model without starting over. The features must stay the same.

### Step 3 · `LEARN_RATE_STRATEGY` and `LEARN_RATE`: how big each step is

By default (`LEARN_RATE_STRATEGY = 'LINE_SEARCH'`) BigQuery tries step sizes and picks a good one each time, starting from `LS_INIT_LEARN_RATE`. With `'CONSTANT'` you fix the size yourself with `LEARN_RATE`. Try a tiny one:

```sql
CREATE OR REPLACE MODEL ml.cars_tiny_steps
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         optimize_strategy = 'BATCH_GRADIENT_DESCENT',
         learn_rate_strategy = 'CONSTANT', learn_rate = 0.001) AS
SELECT * FROM ml.cars_clean;

SELECT iteration, ROUND(loss, 2) AS loss, ROUND(eval_loss, 2) AS eval_loss
FROM ML.TRAINING_INFO(MODEL ml.cars_tiny_steps)
ORDER BY iteration;
```

**What you should see:** the loss falls very slowly, or early stopping ends training while the loss is still high. Score it with `ML.EVALUATE`: far worse than `cars_steps`.

Now try `learn_rate = 0.1`, then `learn_rate = 1.0`. Watch the loss column each time. Too small: it crawls. About right: it falls fast and settles. Too big: it can jump around instead of settling.

**Think:** why does the default try step sizes for you?

## Part B · Holding the weights back: regularization

### Step 4 · Why hold weights back at all?

Four of the five car features describe one thing: how big the engine and the car are. `cylinders`, `displacement`, `horsepower` and `weight` rise together. When features carry the same information, the model can share the credit between them in many ways that fit almost equally well, and small changes in the data can swing their weights a lot. See how closely they move together:

```sql
SELECT ROUND(CORR(displacement, weight), 2) AS displacement_weight,
       ROUND(CORR(displacement, cylinders), 2) AS displacement_cylinders,
       ROUND(CORR(horsepower, weight), 2) AS horsepower_weight
FROM ml.cars_clean;
```

**What you should see:** all three above 0.85. A **penalty** on large weights makes training prefer smaller, more evenly shared weights. That is **regularization**: the training goal becomes *small errors plus small weights*.

### Step 5 · `L2_REG`: shrink every weight a little

```sql
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
```

Standardized weights (lab 06, step 5) put every feature on one yardstick, so you can compare sizes.

**What you should see:** with L2, every weight is closer to zero, and the four engine features share the credit more evenly. No weight becomes exactly zero. Compare `ML.EVALUATE` for both: the scores are close, often a little lower with the penalty on data this small.

Try `l2_reg = 500`. **Think:** what happens to the weights, and to R², as the penalty grows?

### Step 6 · `L1_REG`: push weak weights to exactly zero

```sql
CREATE OR REPLACE MODEL ml.cars_l1
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['mpg'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         l1_reg = 50) AS
SELECT * FROM ml.cars_clean;

SELECT processed_input, ROUND(weight, 3) AS weight
FROM ML.WEIGHTS(MODEL ml.cars_l1, STRUCT(TRUE AS standardize))
ORDER BY ABS(weight) DESC;
```

**What you should see:** some weights are exactly 0. The first to go are the features the model needs least, usually `acceleration` and `displacement`; `weight` survives longest. L1 chooses features for you: a weight of zero means the model no longer uses that column.

Run `ML.TRAINING_INFO` on `cars_l1`: several rows. An L1 penalty cannot be solved in one calculation, so BigQuery trains it step by step.

Try `l1_reg = 200`. **Think:** if you had 50 columns and only wanted to keep the useful ones, which of the two penalties would you use, and why?

## Part C (stretch) · Let BigQuery try the settings for you: hyperparameter tuning

The options you set by hand (`L1_REG`, `L2_REG`, `LEARN_RATE` …) are **hyperparameters**: settings chosen before training, not numbers learned from the data. Instead of trying values one by one, BigQuery can train several versions (**trials**) and keep the best. You give a range instead of a value, and say how many trials to run:

```sql
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
```

What is new:

- **`NUM_TRIALS`** and **`MAX_PARALLEL_TRIALS`**: how many versions to train, and how many at once.
- **`HPARAM_RANGE(0, 20)`**: "try values between 0 and 20". `HPARAM_CANDIDATES([0, 1, 10])` lists exact values to try instead.
- **`HPARAM_TUNING_ALGORITHM`**: how the next value is chosen: `GRID_SEARCH` (every combination), `RANDOM_SEARCH`, or `VIZIER_DEFAULT` (Google's search, which learns from earlier trials).
- **`HPARAM_TUNING_OBJECTIVES`**: the score that decides which trial is best, here R².
- **`DATA_SPLIT_TEST_FRACTION`**: now there are three groups. Each trial trains on the training rows and is compared on the evaluation rows; the winner is scored once on the **test** rows, which played no part in choosing it.

**What you should see:** ten rows, each with the L1 and L2 values that trial used and its R²; one row has `is_optimal = true`. On a dataset this small the best trials score about the same as no penalty at all. That is a finding too: regularization matters most with many features and few rows.

If the sandbox refuses this statement, read the output description above and move on; tuning is optional here.

## Every option on the page, and where you meet it

| Option | Where |
|---|---|
| `MODEL_TYPE`, `INPUT_LABEL_COLS` | class, activities 02–04 |
| `DATA_SPLIT_METHOD`, `DATA_SPLIT_EVAL_FRACTION`, `DATA_SPLIT_COL` | lab 05 |
| `DATA_SPLIT_TEST_FRACTION`, `NUM_TRIALS`, `MAX_PARALLEL_TRIALS`, `HPARAM_TUNING_ALGORITHM`, `HPARAM_TUNING_OBJECTIVES` | lab 07, part C |
| `FIT_INTERCEPT`, `CATEGORY_ENCODING_METHOD`, `CALCULATE_P_VALUES`, `ENABLE_GLOBAL_EXPLAIN` | lab 06 |
| `OPTIMIZE_STRATEGY`, `MAX_ITERATIONS`, `EARLY_STOP`, `MIN_REL_PROGRESS`, `LEARN_RATE_STRATEGY`, `LEARN_RATE`, `LS_INIT_LEARN_RATE`, `WARM_START`, `L1_REG`, `L2_REG` | lab 07 |
| `AUTO_CLASS_WEIGHTS`, `CLASS_WEIGHTS` | D12: they exist only for classification |
| `MODEL_REGISTRY`, `VERTEX_AI_MODEL_ID`, `VERTEX_AI_MODEL_VERSION_ALIASES`, `KMS_KEY_NAME` | not in this course: they register a model in Vertex AI or encrypt it with your own key, which production teams use |

## What you saw

| Option | Value tried | What you saw in `ML.TRAINING_INFO`, `ML.WEIGHTS` or `ML.EVALUATE` |
|---|---|---|
| `OPTIMIZE_STRATEGY` | NORMAL_EQUATION / BATCH_GRADIENT_DESCENT | |
| `MAX_ITERATIONS` | 2 | |
| `LEARN_RATE` (CONSTANT) | 0.001 / 0.1 / 1.0 | |
| `L2_REG` | 50 / 500 | |
| `L1_REG` | 50 / 200 | |
| `WARM_START` | TRUE | |
| `NUM_TRIALS` with `HPARAM_RANGE` | 10 trials | |

These options are not special to linear regression. Logistic regression (D12) has the same ones, and other models have their own versions of them.

## References

Auto MPG, UCI Machine Learning Repository (Quinlan, 1993), CC BY 4.0. BigQuery ML: [CREATE MODEL for linear regression](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-glm), [ML.TRAINING_INFO](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-train), [ML.WEIGHTS](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-weights), Google Cloud.
