-- D13 · Lab 06 · Where k-means starts, and when it stops · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

-- Step 1 · Training, round by round
SELECT training_run, iteration, ROUND(loss, 3) AS loss, duration_ms
FROM ML.TRAINING_INFO(MODEL ml.mall_segments)
ORDER BY iteration;

-- Step 2 · Random starts against KMEANS++ starts
CREATE OR REPLACE MODEL ml.mall_random
OPTIONS (model_type = 'KMEANS', num_clusters = 5, kmeans_init_method = 'RANDOM') AS
SELECT annual_income_k, spending_score FROM ml.mall;

SELECT 'RANDOM' AS starts, COUNT(*) AS rounds, ROUND(MIN(loss), 3) AS final_loss
FROM ML.TRAINING_INFO(MODEL ml.mall_random)
UNION ALL
SELECT 'KMEANS++', COUNT(*), ROUND(MIN(loss), 3)
FROM ML.TRAINING_INFO(MODEL ml.mall_segments);

-- Step 3 · Start from shoppers you choose
CREATE OR REPLACE MODEL ml.mall_custom
OPTIONS (model_type = 'KMEANS', num_clusters = 5,
         kmeans_init_method = 'CUSTOM', kmeans_init_col = 'is_start') AS
SELECT annual_income_k, spending_score,
       customer_id IN (1, 2, 41, 124, 125) AS is_start
FROM ml.mall;

SELECT iteration, ROUND(loss, 3) AS loss
FROM ML.TRAINING_INFO(MODEL ml.mall_custom)
ORDER BY iteration;

-- Step 4 · Stop after one round
CREATE OR REPLACE MODEL ml.mall_one_round
OPTIONS (model_type = 'KMEANS', num_clusters = 5, kmeans_init_method = 'KMEANS++',
         max_iterations = 1) AS
SELECT annual_income_k, spending_score FROM ml.mall;

SELECT ROUND(mean_squared_distance, 3) AS mean_squared_distance
FROM ML.EVALUATE(MODEL ml.mall_one_round);

-- Step 5 · When does training stop by itself?
CREATE OR REPLACE MODEL ml.mall_no_early_stop
OPTIONS (model_type = 'KMEANS', num_clusters = 5, kmeans_init_method = 'KMEANS++',
         early_stop = FALSE) AS
SELECT annual_income_k, spending_score FROM ml.mall;

CREATE OR REPLACE MODEL ml.mall_impatient
OPTIONS (model_type = 'KMEANS', num_clusters = 5, kmeans_init_method = 'KMEANS++',
         min_rel_progress = 0.1) AS
SELECT annual_income_k, spending_score FROM ml.mall;

SELECT 'early_stop = FALSE' AS run, COUNT(*) AS rounds, ROUND(MIN(loss), 3) AS final_loss
FROM ML.TRAINING_INFO(MODEL ml.mall_no_early_stop)
UNION ALL
SELECT 'min_rel_progress = 0.1', COUNT(*), ROUND(MIN(loss), 3)
FROM ML.TRAINING_INFO(MODEL ml.mall_impatient);

-- Step 6 · Continue a model on new rows
CREATE OR REPLACE MODEL ml.mall_warm
OPTIONS (model_type = 'KMEANS', num_clusters = 5, kmeans_init_method = 'KMEANS++') AS
SELECT annual_income_k, spending_score FROM ml.mall
WHERE customer_id <= 150;

CREATE OR REPLACE MODEL ml.mall_warm
OPTIONS (model_type = 'KMEANS', num_clusters = 5, warm_start = TRUE) AS
SELECT annual_income_k, spending_score FROM ml.mall;

SELECT training_run, iteration, ROUND(loss, 3) AS loss
FROM ML.TRAINING_INFO(MODEL ml.mall_warm)
ORDER BY training_run, iteration;
