-- D13 · Lab 05 · Choosing k, and letting BigQuery try · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

-- Step 1 · Leave the number of groups out
CREATE OR REPLACE MODEL ml.mall_default_k
OPTIONS (model_type = 'KMEANS', kmeans_init_method = 'KMEANS++') AS
SELECT annual_income_k, spending_score
FROM ml.mall;

SELECT COUNT(DISTINCT centroid_id) AS groups
FROM ML.CENTROIDS(MODEL ml.mall_default_k);

-- Step 2 · Four values of k, side by side
CREATE OR REPLACE MODEL ml.mall_k3
OPTIONS (model_type = 'KMEANS', num_clusters = 3, kmeans_init_method = 'KMEANS++') AS
SELECT annual_income_k, spending_score FROM ml.mall;

CREATE OR REPLACE MODEL ml.mall_k4
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++') AS
SELECT annual_income_k, spending_score FROM ml.mall;

CREATE OR REPLACE MODEL ml.mall_k6
OPTIONS (model_type = 'KMEANS', num_clusters = 6, kmeans_init_method = 'KMEANS++') AS
SELECT annual_income_k, spending_score FROM ml.mall;

SELECT 3 AS k, ROUND(davies_bouldin_index, 2) AS davies_bouldin, ROUND(mean_squared_distance, 2) AS msd
FROM ML.EVALUATE(MODEL ml.mall_k3)
UNION ALL SELECT 4, ROUND(davies_bouldin_index, 2), ROUND(mean_squared_distance, 2) FROM ML.EVALUATE(MODEL ml.mall_k4)
UNION ALL SELECT 5, ROUND(davies_bouldin_index, 2), ROUND(mean_squared_distance, 2) FROM ML.EVALUATE(MODEL ml.mall_segments)
UNION ALL SELECT 6, ROUND(davies_bouldin_index, 2), ROUND(mean_squared_distance, 2) FROM ML.EVALUATE(MODEL ml.mall_k6)
ORDER BY k;

-- Step 3 · Profiles for k = 4
SELECT centroid_id, COUNT(*) AS shoppers,
       ROUND(AVG(annual_income_k), 1) AS avg_income_k, ROUND(AVG(spending_score), 1) AS avg_score,
       ROUND(AVG(age), 1) AS avg_age
FROM ML.PREDICT(MODEL ml.mall_k4, (SELECT * FROM ml.mall))
GROUP BY centroid_id
ORDER BY avg_income_k;

-- Step 4 · Let BigQuery try nine values
CREATE OR REPLACE MODEL ml.mall_tuned
OPTIONS (
  model_type = 'KMEANS',
  kmeans_init_method = 'KMEANS++',
  num_clusters = HPARAM_RANGE(2, 10),
  num_trials = 9,
  max_parallel_trials = 3,
  hparam_tuning_objectives = ['DAVIES_BOULDIN_INDEX']
) AS
SELECT annual_income_k, spending_score
FROM ml.mall;

SELECT trial_id,
       hyperparameters.num_clusters AS k,
       ROUND(hparam_tuning_evaluation_metrics.davies_bouldin_index, 3) AS davies_bouldin,
       status, is_optimal
FROM ML.TRIAL_INFO(MODEL ml.mall_tuned)
ORDER BY k;
