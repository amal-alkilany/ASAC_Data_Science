-- D15 · Lab 11 · Explaining models, argument by argument · Starter
-- Self-guided: run one statement at a time, after reading its step in the README.
-- The README explains each step: read it first, run the SQL, then compare with "What you should see".

-- Step 1 · The five people, once, as a view
CREATE OR REPLACE VIEW ml.five_people AS
SELECT CASE ROUND(charges, 2)
         WHEN 4391.65 THEN 'A' WHEN 10370.91 THEN 'B' WHEN 13228.85 THEN 'C'
         WHEN 17904.53 THEN 'D' WHEN 43578.94 THEN 'E'
       END AS person,
       age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'validation'
  AND ROUND(charges, 2) IN (4391.65, 10370.91, 13228.85, 17904.53, 43578.94);

SELECT person, age, smoker, ROUND(bmi, 1) AS bmi FROM ml.five_people ORDER BY person;

-- Step 2 · top_k_features
SELECT e.person, COUNT(*) AS attributions_returned,
       STRING_AGG(a.feature ORDER BY ABS(a.attribution) DESC) AS features_by_size
FROM ML.EXPLAIN_PREDICT(MODEL ml.ins_boosted,
  (SELECT * FROM ml.five_people),
  STRUCT(5 AS top_k_features)) AS e,
  UNNEST(e.top_feature_attributions) AS a
GROUP BY e.person
ORDER BY e.person;

-- Step 3 · Every output column
SELECT person, charges,
       ROUND(predicted_charges, 2) AS predicted_charges,
       ROUND(baseline_prediction_value, 2) AS baseline_prediction_value,
       ROUND(prediction_value, 2) AS prediction_value,
       approximation_error,
       ROUND(baseline_prediction_value
             + (SELECT SUM(a.attribution) FROM UNNEST(top_feature_attributions) AS a), 2) AS rebuilt
FROM ML.EXPLAIN_PREDICT(MODEL ml.ins_boosted,
  (SELECT * FROM ml.five_people),
  STRUCT(6 AS top_k_features))
ORDER BY person;

-- Step 4 · approx_feature_contrib
SELECT ex.person, ex.feature,
       ROUND(ex.attribution) AS exact_attribution,
       ROUND(ap.attribution) AS approximate_attribution
FROM (
  SELECT e.person, a.feature, a.attribution
  FROM ML.EXPLAIN_PREDICT(MODEL ml.ins_boosted, (SELECT * FROM ml.five_people),
                          STRUCT(6 AS top_k_features, FALSE AS approx_feature_contrib)) AS e,
       UNNEST(e.top_feature_attributions) AS a
) AS ex
JOIN (
  SELECT e.person, a.feature, a.attribution
  FROM ML.EXPLAIN_PREDICT(MODEL ml.ins_boosted, (SELECT * FROM ml.five_people),
                          STRUCT(6 AS top_k_features, TRUE AS approx_feature_contrib)) AS e,
       UNNEST(e.top_feature_attributions) AS a
) AS ap
  ON ex.person = ap.person AND ex.feature = ap.feature
ORDER BY ex.person, ABS(ex.attribution) DESC;

-- Step 6 · A classifier: threshold, probability and log-odds
SELECT split, COUNT(*) AS customers
FROM ml.telco_groups
GROUP BY split
ORDER BY customers DESC;

SELECT customerID, Churn, predicted_Churn, ROUND(probability, 3) AS probability,
       ROUND(prediction_value, 3) AS log_odds, top_feature_attributions
FROM ML.EXPLAIN_PREDICT(MODEL ml.telco_boosted,
  (SELECT * FROM ml.telco_groups WHERE split = 'validation' ORDER BY customerID LIMIT 5),
  STRUCT(3 AS top_k_features, 0.5 AS threshold))
ORDER BY customerID;

-- Step 7 · ML.GLOBAL_EXPLAIN, and why the option is needed
SELECT feature, ROUND(attribution) AS attribution
FROM ML.GLOBAL_EXPLAIN(MODEL ml.ins_explain)
ORDER BY attribution DESC;

SELECT feature, attribution
FROM ML.GLOBAL_EXPLAIN(MODEL ml.ins_boosted);

-- Step 8 · class_level_explain on a classifier
CREATE OR REPLACE MODEL ml.telco_explain
OPTIONS (model_type = 'BOOSTED_TREE_CLASSIFIER',
         input_label_cols = ['Churn'],
         data_split_method = 'NO_SPLIT',
         enable_global_explain = TRUE) AS
SELECT tenure, MonthlyCharges, Contract, InternetService, PaymentMethod,
       SeniorCitizen, PaperlessBilling, TechSupport, Churn
FROM ml.telco_groups
WHERE split = 'train';

SELECT feature, ROUND(attribution, 3) AS attribution
FROM ML.GLOBAL_EXPLAIN(MODEL ml.telco_explain)
ORDER BY attribution DESC;

SELECT *
FROM ML.GLOBAL_EXPLAIN(MODEL ml.telco_explain, STRUCT(TRUE AS class_level_explain));

-- Step 9 · Global importance, the long way
SELECT a.feature, ROUND(AVG(ABS(a.attribution)), 2) AS mean_abs_attribution
FROM ML.EXPLAIN_PREDICT(MODEL ml.ins_boosted,
  (SELECT * FROM ml.insurance_groups WHERE split = 'validation'),
  STRUCT(6 AS top_k_features)) AS e,
  UNNEST(e.top_feature_attributions) AS a
GROUP BY a.feature
ORDER BY mean_abs_attribution DESC;

-- Step 10 · Three rankings side by side
SELECT g.feature,
       ROUND(g.attribution) AS global_attribution,
       f.importance_weight,
       ROUND(f.importance_gain, 1) AS importance_gain,
       ROUND(f.importance_cover, 1) AS importance_cover
FROM ML.GLOBAL_EXPLAIN(MODEL ml.ins_explain) AS g
JOIN ML.FEATURE_IMPORTANCE(MODEL ml.ins_explain) AS f
  ON g.feature = f.feature
ORDER BY global_attribution DESC;
