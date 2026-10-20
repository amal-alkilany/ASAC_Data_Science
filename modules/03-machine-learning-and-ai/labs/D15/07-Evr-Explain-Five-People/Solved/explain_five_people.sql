-- D15 · Explain five people, then the model overall · Solved (every query from the README, in order)
-- Run one statement at a time, in order. CREATE MODEL and the ML. functions run in BigQuery only.

-- Step 1 · Five people, and why the model priced them
SELECT age, sex, bmi, children, smoker, region, ROUND(charges, 2) AS charges, split
FROM ml.insurance_groups
WHERE split = 'validation'
  AND ROUND(charges, 2) IN (4391.65, 10370.91, 13228.85, 17904.53, 43578.94)
ORDER BY charges;

SELECT charges, ROUND(predicted_charges) AS prediction,
       ROUND(baseline_prediction_value) AS baseline,
       top_feature_attributions
FROM ML.EXPLAIN_PREDICT(MODEL ml.ins_boosted,
  (SELECT age, sex, bmi, children, smoker, region, charges
   FROM ml.insurance_groups
   WHERE split = 'validation'
     AND ROUND(charges, 2) IN (4391.65, 10370.91, 13228.85, 17904.53, 43578.94)),
  STRUCT(6 AS top_k_features))
ORDER BY charges;

-- Step 2 · The pieces add up
SELECT e.charges, a.feature, ROUND(a.attribution) AS attribution
FROM ML.EXPLAIN_PREDICT(MODEL ml.ins_boosted,
  (SELECT age, sex, bmi, children, smoker, region, charges
   FROM ml.insurance_groups
   WHERE split = 'validation'
     AND ROUND(charges, 2) IN (4391.65, 10370.91, 13228.85, 17904.53, 43578.94)),
  STRUCT(6 AS top_k_features)) AS e,
  UNNEST(e.top_feature_attributions) AS a
ORDER BY e.charges, ABS(a.attribution) DESC;

-- Step 3 · The model overall
CREATE OR REPLACE MODEL ml.ins_explain
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT',
         enable_global_explain = TRUE) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

SELECT feature, ROUND(attribution) AS attribution
FROM ML.GLOBAL_EXPLAIN(MODEL ml.ins_explain)
ORDER BY attribution DESC;

SELECT feature, importance_weight, ROUND(importance_gain, 1) AS importance_gain
FROM ML.FEATURE_IMPORTANCE(MODEL ml.ins_boosted)
ORDER BY importance_gain DESC;

-- Step 4 · Explain person D to the pricing team
-- Sample sentence for the pricing team (values computed outside BigQuery; BigQuery's may differ a little):
-- "Smoking adds about 14,000 dollars to D's predicted charge, and his BMI of about 25 takes about 7,100
-- back off, because in this model BMI matters mostly for smokers; being 33 takes off about 2,000 more."
-- Common error: "BMI lowers charges". The push depends on the person: a low BMI pulls a smoker's prediction down.

-- Step 5 · If the trees will not train: the prepared file
SELECT person, prediction, baseline, contrib_smoker, contrib_age, contrib_bmi,
       ROUND(baseline + contrib_age + contrib_bmi + contrib_children
             + contrib_sex + contrib_smoker + contrib_region, 2) AS rebuilt
FROM ml.d15_explain
ORDER BY person;

SELECT person, feature, attribution
FROM (
  SELECT person, 'smoker' AS feature, contrib_smoker AS attribution FROM ml.d15_explain
  UNION ALL SELECT person, 'age', contrib_age FROM ml.d15_explain
  UNION ALL SELECT person, 'bmi', contrib_bmi FROM ml.d15_explain
  UNION ALL SELECT person, 'children', contrib_children FROM ml.d15_explain
  UNION ALL SELECT person, 'sex', contrib_sex FROM ml.d15_explain
  UNION ALL SELECT person, 'region', contrib_region FROM ml.d15_explain
)
ORDER BY person, ABS(attribution) DESC;
