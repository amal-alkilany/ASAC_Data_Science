# Lab 09 (optional, self-study) · Nakheel's customers, by rule and by k-means

In this optional self-guided lab, you will group Nakheel's customers two ways: with recency, frequency and spend tiers a person defines in SQL, and with k-means, three times, until the groups are usable. Then you will check each group against what its customers spent after the cutoff.

**When:** after labs 05–08, at your own pace, about 50 minutes. Optional; not submitted. · **Data:** `ml.customer_features` (built in D11's optional lab 08) · **SQL:** `Solved/nakheel_segments.sql`

## Before you start

You need the view `ml.customer_features` from [D11 lab 08](../../D11/08-Lab-Nakheel-End-To-End/README.md), step 3. If you have not done it, run that step first: it needs only the `nakheel` tables from D04. One row is one customer with at least one completed order before the **1 March 2026 cutoff**: 412 customers.

The view's columns come from two sides of the cutoff. `days_since_last`, `orders_before` and `revenue_before` use only orders before 1 March: they may be features. `revenue_next_6m` is spend in the six months after: we never cluster on it, and use it only at the end to check the groups. The week's question for every column: *does it use any order after the cutoff?*

Work like the other labs: run each query, compare with **What you should see**, and answer **Think** in one line. Values were computed outside BigQuery on the course files and have not been run in BigQuery yet.

## Step 1 · Look at the three columns

```sql
SELECT COUNT(*) AS customers,
       APPROX_QUANTILES(days_since_last, 4) AS days_quartiles,
       APPROX_QUANTILES(orders_before, 4) AS orders_quartiles,
       APPROX_QUANTILES(revenue_before, 4) AS spend_quartiles
FROM ml.customer_features;
```

**What you should see:** 412 customers. Days since the last order run from 1 to 540, median about 123. Orders: median 2, but up to 86. Spend: median about 198 JOD, but up to about 25,360. Orders and spend have heavy tails, like the wholesaler's spending in lab 07; days do not.

## Step 2 · Tiers the business way: RFM

Marketing often groups customers by three numbers: **R**ecency (how recently they bought), **F**requency (how often) and **M**onetary value (how much). Each customer gets a tier from 1 (best) to 4 on each, by quarters.

```sql
CREATE OR REPLACE VIEW ml.customer_rfm AS
SELECT customer_id, days_since_last, orders_before, revenue_before, revenue_next_6m,
       NTILE(4) OVER (ORDER BY days_since_last, customer_id) AS r_tier,
       NTILE(4) OVER (ORDER BY orders_before DESC, customer_id) AS f_tier,
       NTILE(4) OVER (ORDER BY revenue_before DESC, customer_id) AS m_tier
FROM ml.customer_features;

SELECT CONCAT(CAST(r_tier AS STRING), CAST(f_tier AS STRING), CAST(m_tier AS STRING)) AS rfm, COUNT(*) AS customers
FROM ml.customer_rfm
GROUP BY rfm
ORDER BY customers DESC
LIMIT 6;
```

`NTILE(4)` (D10) cuts the ordered customers into four groups of equal size: 103 each here. `customer_id` in each `ORDER BY` breaks ties, so the same customer always gets the same tier.

`CAST(… AS STRING)` turns each tier into text so `CONCAT` can join them into a code such as 111.

**What you should see:** 49 different codes. The most common are 111 (48 customers: recent, frequent, big spenders) and 444 (31: the opposite). A person chose every rule here: quarters, the order of the three letters, what "best" means.

## Step 3 · k-means on the raw columns

```sql
CREATE OR REPLACE MODEL ml.nakheel_seg_a
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++',
         standardize_features = FALSE) AS
SELECT days_since_last, orders_before, revenue_before
FROM ml.customer_features;

SELECT centroid_id, COUNT(*) AS customers
FROM ML.PREDICT(MODEL ml.nakheel_seg_a, (SELECT * FROM ml.customer_features))
GROUP BY centroid_id
ORDER BY customers DESC;
```

**What you should see:** about 353 · 49 · 8 · 2 (or one huge group and three tiny ones). Spend in dinars runs to thousands while orders run to tens: spend decides every distance, as the penguins' grams did in class.

## Step 4 · Scaled

The same statement with one option changed:

```sql
CREATE OR REPLACE MODEL ml.nakheel_seg_b
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++',
         standardize_features = TRUE) AS
SELECT days_since_last, orders_before, revenue_before
FROM ml.customer_features;

SELECT centroid_id, COUNT(*) AS customers
FROM ML.PREDICT(MODEL ml.nakheel_seg_b, (SELECT * FROM ml.customer_features))
GROUP BY centroid_id
ORDER BY customers DESC;
```

**What you should see:** about 254 · 151 · 5 · 2. The columns now count equally, but a handful of huge spenders still sit so far out that they get groups of their own. Scaling fixed the units, not the tail.

## Step 5 · Logs, then scaled

```sql
CREATE OR REPLACE VIEW ml.customer_features_log AS
SELECT *, LN(1 + orders_before) AS log_orders, LN(1 + revenue_before) AS log_revenue
FROM ml.customer_features;

CREATE OR REPLACE MODEL ml.nakheel_seg_c
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++',
         standardize_features = TRUE) AS
SELECT days_since_last, log_orders, log_revenue
FROM ml.customer_features_log;
```

`days_since_last` is not logged: it has no heavy tail.

## Step 6 · Profile, and check against what happened next

```sql
SELECT centroid_id, COUNT(*) AS customers,
       ROUND(AVG(days_since_last)) AS avg_days,
       ROUND(AVG(orders_before), 1) AS avg_orders,
       ROUND(AVG(revenue_before)) AS avg_spend,
       ROUND(AVG(revenue_next_6m)) AS avg_spend_after,
       ROUND(COUNTIF(revenue_next_6m = 0) / COUNT(*), 2) AS share_bought_nothing_after
FROM ML.PREDICT(MODEL ml.nakheel_seg_c, (SELECT * FROM ml.customer_features_log))
GROUP BY centroid_id
ORDER BY avg_spend;
```

**What you should see:** four groups of usable size. Nakheel's groups move more between runs than the mall's; one run outside BigQuery gave:

| Customers | Avg days | Avg orders | Avg spend | Avg spend after | Bought nothing after |
|---:|---:|---:|---:|---:|---:|
| about 108 | 146 | 1.3 | 78 | 48 | 0.63 |
| about 90 | 388 | 1.4 | 161 | 87 | 0.63 |
| about 151 | 94 | 3.7 | 354 | 147 | 0.34 |
| about 63 | 36 | 18.3 | 2,285 | 884 | 0.10 |

The groups were made without the spend after the cutoff, and they still separate it: the frequent, recent big buyers spent most afterwards, and only one in ten bought nothing.

**Think:** name the four groups and give each one action. Which group would you call first?

## Step 7 · Rules against clusters

```sql
SELECT r.r_tier, p.centroid_id, COUNT(*) AS customers
FROM ML.PREDICT(MODEL ml.nakheel_seg_c, (SELECT * FROM ml.customer_features_log)) AS p
JOIN ml.customer_rfm AS r USING (customer_id)
GROUP BY r.r_tier, p.centroid_id
ORDER BY r.r_tier, p.centroid_id;
```

**What you should see:** the least recent quarter (`r_tier` 4) falls almost entirely into one cluster, the long-gone customers. The other tiers spread over several clusters, because the clusters weigh all three columns at once.

**Think:** RFM tiers are rules a person wrote; clusters come from the data. When would marketing prefer each?

## What you saw

| Run | Sizes | What it shows |
|---|---|---|
| A, raw | | |
| B, scaled | | |
| C, logs and scaled | | |

## References

Nakheel Retail (course data), [`shared/datasets/nakheel`](../../../../../shared/datasets/nakheel/README.md). BigQuery ML: [CREATE MODEL for k-means](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-kmeans), Google Cloud. `NTILE`: [numbering functions](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/numbering_functions#ntile), Google Cloud.
