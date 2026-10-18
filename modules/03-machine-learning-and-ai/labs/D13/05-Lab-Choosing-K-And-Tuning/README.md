# Lab 05 · Choosing k, and letting BigQuery try

In this self-guided lab, you will see what happens when you leave the number of groups out, compare four values of k by their scores and their profiles, and then ask BigQuery to try nine values for you with hyperparameter tuning.

**When:** after class, about 35 minutes, at your own pace. Not submitted. · **Data:** `ml.mall` · **SQL:** `Solved/choosing_k_and_tuning.sql`

## The story

In class, marketing got five groups because we asked for five. Your manager asks the fair question: *why five, and not four or six?* There is no test score to settle it. This lab collects the evidence BigQuery can give, and shows where it stops and the business decision starts.

## What you will learn

- What `NUM_CLUSTERS` does, including its default.
- Why mean squared distance cannot choose k, and what the Davies–Bouldin index adds.
- How `NUM_TRIALS`, `HPARAM_RANGE`, `HPARAM_CANDIDATES` and `ML.TRIAL_INFO` work for k-means.

## Before you start

You need `ml.mall` and `ml.mall_segments` from [activity 01](../01-Evr-First-Segments/README.md). If `ml.mall_segments` is missing, run activity 01's block 3 first.

Work like the other labs: run each query, compare with **What you should see**, and answer **Think** in one line. The values were computed outside BigQuery with the same settings and have not been run in BigQuery yet; random starts move them a little.

## Step 1 · Leave the number of groups out

```sql
CREATE OR REPLACE MODEL ml.mall_default_k
OPTIONS (model_type = 'KMEANS', kmeans_init_method = 'KMEANS++') AS
SELECT annual_income_k, spending_score
FROM ml.mall;

SELECT COUNT(DISTINCT centroid_id) AS groups
FROM ML.CENTROIDS(MODEL ml.mall_default_k);
```

Google's page says the default is log10(n), where n is the number of rows: log10(200) ≈ 2.3.

**What you should see:** a small number of groups, 2 if BigQuery rounds down. With two groups the split changes from run to run: sometimes higher against lower incomes, sometimes the high-income low spenders against everyone else. None of them shows the five kinds of shopper you saw in class.

**Think:** the default depends only on the row count. Why can't it know how many groups your data has?

## Step 2 · Four values of k, side by side

```sql
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
```

**What you should see:**

| k | Davies–Bouldin | Mean squared distance |
|---:|---:|---:|
| 3 | ≈ 0.72 | ≈ 0.78 |
| 4 | ≈ 0.71 | ≈ 0.54 |
| 5 | ≈ 0.57 | ≈ 0.33 |
| 6 | ≈ 0.63–0.67 | ≈ 0.27–0.29 |

Mean squared distance falls every time k grows. It would reach 0 with 200 groups of one shopper each, which is no use to marketing. The Davies–Bouldin index also weighs how far apart the groups are, so it can rise again: here it is lowest at 5. If one of your rows is much higher, that run landed in a worse split (lab 06 explains why); train it again.

**Think:** the index prefers 5. Name one business reason to choose 4, and one to choose 6.

## Step 3 · Profiles for k = 4

```sql
SELECT centroid_id, COUNT(*) AS shoppers,
       ROUND(AVG(annual_income_k), 1) AS avg_income_k, ROUND(AVG(spending_score), 1) AS avg_score,
       ROUND(AVG(age), 1) AS avg_age
FROM ML.PREDICT(MODEL ml.mall_k4, (SELECT * FROM ml.mall))
GROUP BY centroid_id
ORDER BY avg_income_k;
```

**What you should see:** about 23 · 100 · 39 · 38 shoppers. The two young, low-income big spenders and the middle group have merged into one group of about 100 with average income near 48 thousand and score near 57. Compare with the five-group profile from activity 04.

## Step 4 · Let BigQuery try nine values

```sql
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
```

- `num_trials = 9`: train up to nine models. Without it there is no tuning.
- `num_clusters = HPARAM_RANGE(2, 10)`: any whole number from 2 to 10. `HPARAM_CANDIDATES([3, 4, 5, 6])` would give a list instead.
- `max_parallel_trials = 3`: three at a time, which is faster. The page warns that with the default search method, parallel trials learn less from each other.
- `hparam_tuning_algorithm` is left at its default, `'VIZIER_DEFAULT'`; `'RANDOM_SEARCH'` and `'GRID_SEARCH'` (lists only) are the others.
- `hparam_tuning_objectives`: Davies–Bouldin is the only objective k-means offers, and the default.

When tuning, BigQuery splits the rows itself: 80% to train each trial, 10% to score it, 10% held back for `ML.EVALUATE`.

**What you should see:** nine rows, one per trial, with `k` from 2 to 10 if the search covered them all. The scores come from only 20 shoppers (10% of 200), so they jump around: in our run outside BigQuery, k = 5, 7, 8 and 10 all scored between 0.51 and 0.57. The trial marked `is_optimal` may well not be 5.

**Think:** with 200 rows, is tuning a good way to choose k? What would you look at instead?

## Step 5 · k is a hyperparameter

A **hyperparameter** is a setting you choose before training; the model does not learn it from the data. You have met others: the threshold (D12), L2 regularisation (D11 lab 07). Tree depth comes on D14. For every one of them the method is the same: try a few values, compare on a score that fits the question, and let the use of the result make the final call.

## What you saw

| Question | Your answer |
|---|---|
| What does BigQuery do when `NUM_CLUSTERS` is left out? | |
| Which score keeps falling as k grows? | |
| Which k did the Davies–Bouldin index prefer? | |
| Which k did tuning mark optimal, and why might it differ? | |

## References

Mall Customer Segmentation Data, [Kaggle](https://www.kaggle.com/datasets/vjchoudhary7/customer-segmentation-tutorial-in-python). BigQuery ML: [CREATE MODEL for k-means](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-kmeans) (`NUM_CLUSTERS`, `NUM_TRIALS`, `MAX_PARALLEL_TRIALS`, `HPARAM_TUNING_ALGORITHM`, `HPARAM_TUNING_OBJECTIVES`), [Hyperparameter tuning overview](https://docs.cloud.google.com/bigquery/docs/hp-tuning-overview), [ML.TRIAL_INFO](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-trial-info), [ML.EVALUATE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-evaluate), Google Cloud.
