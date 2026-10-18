# Lab 06 · Where k-means starts, and when it stops

In this self-guided lab, you will change how k-means picks its starting centres, start it from shoppers you choose, cut its training short, change when it stops, and continue a model on new rows. `ML.TRAINING_INFO` shows what each change does, round by round.

**When:** after class, about 35 minutes, at your own pace. Not submitted. · **Data:** `ml.mall` · **SQL:** `Solved/starts_and_stopping.sql`

## The story

In class, two runs of the same statement could give different groups: about one run in three ended with a group of about 100 shoppers instead of the usual five. Marketing will not accept segments that change every time someone presses Run. This lab looks at the options that control where training starts and when it ends, and at how to get the same groups every time.

## What you will learn

- What `KMEANS_INIT_METHOD` (`RANDOM`, `KMEANS++`, `CUSTOM`) and `KMEANS_INIT_COL` do.
- What `MAX_ITERATIONS`, `EARLY_STOP` and `MIN_REL_PROGRESS` control.
- What `WARM_START` does, and how `ML.TRAINING_INFO` shows it.

## Before you start

You need `ml.mall` and `ml.mall_segments` from [activity 01](../01-Evr-First-Segments/README.md). Run each query, compare with **What you should see**, and answer **Think** in one line. Values were computed outside BigQuery with the same settings and have not been run in BigQuery yet.

## Step 1 · Training, round by round

```sql
SELECT training_run, iteration, ROUND(loss, 3) AS loss, duration_ms
FROM ML.TRAINING_INFO(MODEL ml.mall_segments)
ORDER BY iteration;
```

One row per round of assign-and-update. `loss` is how far shoppers sit from their centres (in scaled units); each round should lower it.

**What you should see:** about 4 to 6 rows, the loss falling fast and then barely moving, ending near 0.33 (or near 0.49 if your run landed in the worse split). Training stopped by itself: the last round improved the loss by less than 1%.

## Step 2 · Random starts against KMEANS++ starts

```sql
CREATE OR REPLACE MODEL ml.mall_random
OPTIONS (model_type = 'KMEANS', num_clusters = 5, kmeans_init_method = 'RANDOM') AS
SELECT annual_income_k, spending_score FROM ml.mall;

SELECT 'RANDOM' AS starts, COUNT(*) AS rounds, ROUND(MIN(loss), 3) AS final_loss
FROM ML.TRAINING_INFO(MODEL ml.mall_random)
UNION ALL
SELECT 'KMEANS++', COUNT(*), ROUND(MIN(loss), 3)
FROM ML.TRAINING_INFO(MODEL ml.mall_segments);
```

- `'RANDOM'`, BigQuery's default: five shoppers picked at random are the first centres. Two of them can land in the same group.
- `'KMEANS++'`: the first centre is random; each next one is picked far from those already chosen, so the starts spread out.

**What you should see:** on this small, clean table both usually end at the same five groups (final loss ≈ 0.33). Random starts usually need a round or two more (about 6 against 5). Both can end in the worse split; run each a few times and you will see it happen to either. On larger, messier tables, `KMEANS++` usually trains a better model, as Google's page says.

**Think:** if both can end in a worse split, what protects you? (Activity 04 had one answer.)

## Step 3 · Start from shoppers you choose

```sql
CREATE OR REPLACE MODEL ml.mall_custom
OPTIONS (model_type = 'KMEANS', num_clusters = 5,
         kmeans_init_method = 'CUSTOM', kmeans_init_col = 'is_start') AS
SELECT annual_income_k, spending_score,
       customer_id IN (1, 2, 41, 124, 125) AS is_start
FROM ml.mall;

SELECT iteration, ROUND(loss, 3) AS loss
FROM ML.TRAINING_INFO(MODEL ml.mall_custom)
ORDER BY iteration;
```

- `kmeans_init_method = 'CUSTOM'` with `kmeans_init_col = 'is_start'`: the rows where `is_start` is `TRUE` become the first centres. There must be exactly `num_clusters` of them, here 5.
- `customer_id IN (…)` returns `TRUE` or `FALSE`: a BOOL column, as the option needs. BigQuery leaves this column out of the features.
- The five shoppers sit in five corners of the scatter: low income with low and high score, the middle, high income with high and low score.

**What you should see:** about 5 rounds, the loss falling from about 0.8 to about 0.33, and the five usual groups (80 · 39 · 36 · 23 · 22). Run it again: the same rounds and the same groups, every time, because nothing in it is random.

**Think:** when would a business want fixed starting centres? What does it cost?

## Step 4 · Stop after one round

```sql
CREATE OR REPLACE MODEL ml.mall_one_round
OPTIONS (model_type = 'KMEANS', num_clusters = 5, kmeans_init_method = 'KMEANS++',
         max_iterations = 1) AS
SELECT annual_income_k, spending_score FROM ml.mall;

SELECT ROUND(mean_squared_distance, 3) AS mean_squared_distance
FROM ML.EVALUATE(MODEL ml.mall_one_round);
```

`max_iterations` caps the rounds; its default is 20.

**What you should see:** usually above 0.33: the median of many runs outside BigQuery was about 0.51. One assign-and-update is rarely enough; the centres have not finished moving.

## Step 5 · When does training stop by itself?

```sql
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
```

- `early_stop` (default `TRUE`): stop after the first round that improves the loss by less than `min_rel_progress`.
- `min_rel_progress` (default 0.01, that is 1%): how much a round must improve to keep going.

**What you should see:** with early stop off, training goes on until nothing moves, usually a round or two more, to the same groups. With `min_rel_progress = 0.1`, training gives up after about 3 rounds, often before the centres have settled; outside BigQuery the median result was about 0.47 instead of 0.33.

**Think:** you met early stopping on D11 (lab 07) for regression. What is the same here, and what is the "loss"?

## Step 6 · Continue a model on new rows

```sql
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
```

The file is sorted by income, so the first 150 shoppers earn at most 78 thousand: the first model has never seen a high earner. `warm_start = TRUE` keeps the model's centres and trains again from them on the new rows. The model type and the columns must stay the same.

**What you should see:** `training_run` 0 (the first 150 shoppers) and `training_run` 1 (all 200), each numbering its rounds from 0. After the warm start the centres move out to cover the high incomes; outside BigQuery the result was the usual five groups (80 · 39 · 36 · 23 · 22).

**Think:** a mall adds members every month. When would you warm-start the segments, and when would you train from scratch?

## What you saw

| Option | Default | What it changed here |
|---|---|---|
| `KMEANS_INIT_METHOD` | `'RANDOM'` | |
| `KMEANS_INIT_COL` | none | |
| `MAX_ITERATIONS` | 20 | |
| `EARLY_STOP` | `TRUE` | |
| `MIN_REL_PROGRESS` | 0.01 | |
| `WARM_START` | `FALSE` | |

Randomness in training is not special to k-means: random splits on D11 and D12 moved the scores too. When a result depends on a random start, run it more than once before you trust it.

## References

Mall Customer Segmentation Data, [Kaggle](https://www.kaggle.com/datasets/vjchoudhary7/customer-segmentation-tutorial-in-python). BigQuery ML: [CREATE MODEL for k-means](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-kmeans) (`KMEANS_INIT_METHOD`, `KMEANS_INIT_COL`, `MAX_ITERATIONS`, `EARLY_STOP`, `MIN_REL_PROGRESS`, `WARM_START`), [ML.TRAINING_INFO](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-train), Google Cloud.
