-- D13 · Lab 08 · The odd ones out: anomalies from a k-means model · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

-- Step 1 · How far is each client from its group?
SELECT p.client_id, p.channel, p.fresh, p.milk, p.grocery, p.frozen, p.detergents_paper, p.delicatessen,
       ROUND(d.distance, 2) AS distance_to_own_group
FROM ML.PREDICT(MODEL ml.wholesale_log_model, (SELECT * FROM ml.wholesale_logs)) AS p,
     UNNEST(p.nearest_centroids_distance) AS d
WHERE d.centroid_id = p.centroid_id
ORDER BY distance_to_own_group DESC
LIMIT 10;

-- Step 2 · Flag the most unusual 2%
SELECT client_id, channel, fresh, milk, grocery, frozen, detergents_paper, delicatessen,
       ROUND(normalized_distance, 2) AS normalized_distance
FROM ML.DETECT_ANOMALIES(MODEL ml.wholesale_log_model,
       STRUCT(0.02 AS contamination),
       (SELECT * FROM ml.wholesale_logs))
WHERE is_anomaly
ORDER BY normalized_distance DESC;

-- Step 3 · Change the contamination
SELECT client_id, channel, ROUND(normalized_distance, 2) AS normalized_distance
FROM ML.DETECT_ANOMALIES(MODEL ml.wholesale_log_model,
       STRUCT(0.05 AS contamination),
       (SELECT * FROM ml.wholesale_logs))
WHERE is_anomaly
ORDER BY normalized_distance DESC;
