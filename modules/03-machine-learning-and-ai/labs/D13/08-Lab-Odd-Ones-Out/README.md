# Lab 08 · The odd ones out: anomalies from a k-means model

In this self-guided lab, you will use the wholesaler's log model from lab 07 to rank clients by how far they sit from every group, and let BigQuery flag the most unusual ones with `ML.DETECT_ANOMALIES`.

**When:** after lab 07, about 25 minutes, at your own pace. Not submitted. · **Data:** `ml.wholesale_logs` and `ml.wholesale_log_model` from lab 07 · **SQL:** `Solved/odd_ones_out.sql`

## The story

The wholesaler's finance team checks unusual accounts by hand each quarter: a client whose spending looks like no one else's may be a typing error, a new kind of business, or a client about to leave. They can check about ten. The question: *which clients are least like any group?*

## What you will learn

- To read `nearest_centroids_distance` as "how far is this row from the groups?".
- What a normalized distance is, and why it is fairer than a plain one.
- How `ML.DETECT_ANOMALIES` and its `contamination` setting turn distances into a flag.

## Before you start

You need the view `ml.wholesale_logs` and the model `ml.wholesale_log_model` from [lab 07](../07-Lab-Logs-And-Cosine/README.md), step 3. Run each query, compare with **What you should see**, and answer **Think** in one line. Values were computed outside BigQuery and have not been run in BigQuery yet. Google's page lists `ML.DETECT_ANOMALIES` as billable; if your sandbox refuses it, read step 3's expected result and go on to step 4.

## Step 1 · How far is each client from its group?

```sql
SELECT p.client_id, p.channel, p.fresh, p.milk, p.grocery, p.frozen, p.detergents_paper, p.delicatessen,
       ROUND(d.distance, 2) AS distance_to_own_group
FROM ML.PREDICT(MODEL ml.wholesale_log_model, (SELECT * FROM ml.wholesale_logs)) AS p,
     UNNEST(p.nearest_centroids_distance) AS d
WHERE d.centroid_id = p.centroid_id
ORDER BY distance_to_own_group DESC
LIMIT 10;
```

`nearest_centroids_distance` holds the distance to every centre; `WHERE d.centroid_id = p.centroid_id` keeps the one to the client's own group. The aliases `p` and `d` matter: both the prediction row and each list item have a `centroid_id`, and BigQuery needs to know which one you mean.

**What you should see:** the clients furthest from their own centre. Look at their rows: several spend almost nothing on one or more products (a 3 where others have thousands).

## Step 2 · Flag the most unusual 2%

```sql
SELECT client_id, channel, fresh, milk, grocery, frozen, detergents_paper, delicatessen,
       ROUND(normalized_distance, 2) AS normalized_distance
FROM ML.DETECT_ANOMALIES(MODEL ml.wholesale_log_model,
       STRUCT(0.02 AS contamination),
       (SELECT * FROM ml.wholesale_logs))
WHERE is_anomaly
ORDER BY normalized_distance DESC;
```

- `contamination = 0.02`: we tell BigQuery to expect about 2% of the training rows to be anomalies. It sets the cut so that about 2% of the training clients fall above it. The value must be between 0 and 0.5.
- `normalized_distance`: the distance to the nearest centre divided by that group's **radius** (the typical distance of its members from the centre). A wide, loose group tolerates more distance than a tight one.
- `is_anomaly` is `TRUE` above the cut.

**What you should see:** about 9 clients (2% of 440). Outside BigQuery, the list almost always included clients **76** (grocery 3, detergents 3), **155** (under 650 on everything), **184** (delicatessen 47,943, the largest in the file), **339** (fresh 3) and **143** (delicatessen 3). Your list can differ at the edges, because the groups depend on the starting centres.

## Step 3 · Change the contamination

The same query with 5% instead of 2%:

```sql
SELECT client_id, channel, ROUND(normalized_distance, 2) AS normalized_distance
FROM ML.DETECT_ANOMALIES(MODEL ml.wholesale_log_model,
       STRUCT(0.05 AS contamination),
       (SELECT * FROM ml.wholesale_logs))
WHERE is_anomaly
ORDER BY normalized_distance DESC;
```

**What you should see:** about 22 clients. The setting does not find "the real anomalies"; it decides how many you want to look at.

**Think:** finance can check about ten accounts a quarter. Which contamination would you set, and what would you tell them about clients just below the cut?

## Step 4 · Anomaly or group of its own?

Think back to step 2 of lab 07, the scaled-but-not-logged model: there, the biggest spenders formed tiny groups of their own, so they sat close to their own centre and would not look odd at all.

**Think:** why does the anomaly ranking need a model whose groups describe most clients well?

## What you saw

| Question | Your answer |
|---|---|
| What does `normalized_distance` divide by? | |
| How many clients did 0.02 flag? 0.05? | |
| Name one flagged client and what makes it unusual | |

## References

Wholesale customers (Cardoso, 2013), UCI Machine Learning Repository, [doi:10.24432/C5030X](https://doi.org/10.24432/C5030X), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). BigQuery ML: [ML.DETECT_ANOMALIES](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-detect-anomalies) (k-means output: `is_anomaly`, `normalized_distance`, `centroid_id`), [ML.PREDICT](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-predict) (`nearest_centroids_distance`), Google Cloud.
