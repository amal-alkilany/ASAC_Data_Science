# Lab 07 · Heavy tails, logs, and grouping by mix: a wholesaler's clients

In this self-guided lab, you will cluster 440 clients of a food wholesaler three ways: on scaled spending, on the logarithm of spending, and by cosine distance, and see that each one answers a different question.

**When:** after class, about 40 minutes, at your own pace. Not submitted. · **Data:** [`wholesale_customers.csv`](../../../../../shared/datasets/ml_classics/wholesale_customers.csv) → `ml.wholesale` · **SQL:** `Solved/logs_and_cosine.sql`

## The story

A wholesale distributor in Portugal sells to hotels, restaurants and cafés (the trade calls them **Horeca**) and to shops (**Retail**). For each client it records a year's spending, in its own monetary units, on six kinds of product: fresh food, milk products, grocery, frozen food, detergents and paper, and delicatessen. The sales director asks: *which kinds of client do we serve, so that each gets the right delivery plan and the right offers?*

## What you will learn

- What a heavy tail is, and why it gives a few clients a group of their own.
- That `LN(1 + x)` and scaling fix different problems, and are often needed together.
- What `DISTANCE_TYPE = 'COSINE'` measures, and when you want it.

## Before you start

Download [`wholesale_customers.csv`](../../../../../shared/datasets/ml_classics/wholesale_customers.csv) and upload it as the table `wholesale` in `ml` (**⋮** → **Create table**, Upload, CSV, **Auto detect**). Check: 440 rows; `channel` is Horeca or Retail, `region` Lisbon, Oporto or Other; the six spending columns are whole numbers.

Run each query, compare with **What you should see**, and answer **Think** in one line. Values were computed outside BigQuery with the same settings and have not been run in BigQuery yet. Clusters of this data move more between runs than the mall's; compare your sizes with the ranges given, not with one number.

## Step 1 · Look at the spending first

```sql
SELECT APPROX_QUANTILES(fresh, 4) AS fresh_quartiles,
       ROUND(AVG(fresh)) AS fresh_avg,
       APPROX_QUANTILES(detergents_paper, 4) AS detergents_quartiles,
       ROUND(AVG(detergents_paper)) AS detergents_avg
FROM ml.wholesale;
```

`APPROX_QUANTILES(x, 4)` returns five values: the smallest, the three quartiles and the largest (approximately).

**What you should see:** fresh food from 3 to 112,151, with a median near 8,500 and an average of 12,000. Half the clients spend less than 8,500; a few spend ten times that, and pull the average up. Detergents and paper: median near 800, average near 2,900. This shape, most values small and a long thin tail of large ones, is a **heavy tail**. Every spending column here has one.

## Step 2 · Scaled, but not logged

```sql
CREATE OR REPLACE MODEL ml.wholesale_scaled
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++',
         standardize_features = TRUE) AS
SELECT fresh, milk, grocery, frozen, detergents_paper, delicatessen
FROM ml.wholesale;

SELECT centroid_id, COUNT(*) AS clients,
       ROUND(COUNTIF(channel = 'Retail') / COUNT(*), 2) AS share_retail,
       APPROX_QUANTILES(fresh, 2)[OFFSET(1)] AS median_fresh,
       APPROX_QUANTILES(grocery, 2)[OFFSET(1)] AS median_grocery
FROM ML.PREDICT(MODEL ml.wholesale_scaled, (SELECT * FROM ml.wholesale))
GROUP BY centroid_id
ORDER BY clients DESC;
```

`APPROX_QUANTILES(x, 2)[OFFSET(1)]` is the median: the middle of three values. A median describes a group better than an average when a few clients are huge.

**What you should see:** one very large group (often about 300 of the 440) and, in most runs, at least one group of 10 clients or fewer: the biggest spenders, alone. Scaling put the six columns in the same units, but inside each column the giants are still many standard deviations from everyone else, so the distance is about them.

## Step 3 · Logs first, then scaling

```sql
CREATE OR REPLACE VIEW ml.wholesale_logs AS
SELECT *,
       LN(1 + fresh) AS log_fresh, LN(1 + milk) AS log_milk, LN(1 + grocery) AS log_grocery,
       LN(1 + frozen) AS log_frozen, LN(1 + detergents_paper) AS log_detergents_paper,
       LN(1 + delicatessen) AS log_delicatessen
FROM ml.wholesale;

CREATE OR REPLACE MODEL ml.wholesale_log_model
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++',
         standardize_features = TRUE) AS
SELECT log_fresh, log_milk, log_grocery, log_frozen, log_detergents_paper, log_delicatessen
FROM ml.wholesale_logs;
```

- `LN(1 + x)`: the natural logarithm of one more than the value. Ten times more spending adds about 2.3, whatever the starting amount, so 1,000 against 10,000 counts as much as 10,000 against 100,000. The `1 +` keeps a spend of 0 from breaking it (`LN(0)` is undefined). Other tools call it `log1p`.
- The view keeps the original columns beside the logged ones, so the profile below can use plain units.

```sql
SELECT centroid_id, COUNT(*) AS clients,
       ROUND(COUNTIF(channel = 'Retail') / COUNT(*), 2) AS share_retail,
       APPROX_QUANTILES(fresh, 2)[OFFSET(1)] AS median_fresh,
       APPROX_QUANTILES(milk, 2)[OFFSET(1)] AS median_milk,
       APPROX_QUANTILES(grocery, 2)[OFFSET(1)] AS median_grocery,
       APPROX_QUANTILES(detergents_paper, 2)[OFFSET(1)] AS median_detergents
FROM ML.PREDICT(MODEL ml.wholesale_log_model, (SELECT * FROM ml.wholesale_logs))
GROUP BY centroid_id
ORDER BY clients DESC;
```

**What you should see:** four groups of usable size; in almost every run the smallest has 20 clients or more. One run outside BigQuery gave about 134 · 123 · 116 · 67: two groups that are nearly all Horeca (one buying lots of fresh and frozen food, one buying some fresh food and little else), and two that are mostly Retail (grocery, milk and detergents; one of them buys almost no fresh food). Your sizes may differ; the kinds of group are what to compare.

**Think:** scaling fixed one problem in step 2 and not another. Say both problems in your own words.

## Step 4 · Group by the mix, not the size

```sql
CREATE OR REPLACE MODEL ml.wholesale_cosine
OPTIONS (model_type = 'KMEANS', num_clusters = 2, kmeans_init_method = 'KMEANS++',
         distance_type = 'COSINE', standardize_features = FALSE) AS
SELECT fresh, milk, grocery, frozen, detergents_paper, delicatessen
FROM ml.wholesale;

SELECT centroid_id, channel, COUNT(*) AS clients
FROM ML.PREDICT(MODEL ml.wholesale_cosine, (SELECT * FROM ml.wholesale))
GROUP BY centroid_id, channel
ORDER BY centroid_id, channel;
```

- `distance_type = 'EUCLIDEAN'` (the default) is the straight-line distance from class: a client who buys 1,000 of everything and one who buys 10,000 of everything are far apart.
- `distance_type = 'COSINE'` compares directions, not lengths: those two clients buy the same **mix** and are close. It answers "what do they buy?" instead of "how much?".
- `standardize_features = FALSE` keeps the spending in its own units, so the mix is the real share of each product.

**What you should see:** two groups of about 257 and 183 clients, the same in almost every run. The first is about 224 Horeca and 32 Retail clients, spending on average about 55% of their money on fresh food. The second is about 74 Horeca and 110 Retail, with grocery the largest share (about 36%). The model never saw `channel`, and still found most of it from the mix alone.

**Think:** which of the three models (steps 2, 3 and 4) would you give a delivery planner, and which a marketing team? Why?

## What you saw

| Fix | The problem it solves | Option or SQL |
|---|---|---|
| Scaling | | `STANDARDIZE_FEATURES` (default `TRUE`) |
| Logs | | `LN(1 + x)` in the `SELECT` |
| Cosine distance | | `DISTANCE_TYPE = 'COSINE'` |

Scaling and heavy tails come back on every ML problem with numbers in different units or a few huge values: regression weights (D11 lab 06) and the trees of D14 among them.

## References

Wholesale customers (Cardoso, 2013), UCI Machine Learning Repository, [doi:10.24432/C5030X](https://doi.org/10.24432/C5030X), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); course copy in [`shared/datasets/ml_classics`](../../../../../shared/datasets/ml_classics/README.md), taken 18 October 2026 (channel and region codes written out as words; `client_id` added). BigQuery ML: [CREATE MODEL for k-means](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-kmeans) (`DISTANCE_TYPE`, `STANDARDIZE_FEATURES`), Google Cloud.
