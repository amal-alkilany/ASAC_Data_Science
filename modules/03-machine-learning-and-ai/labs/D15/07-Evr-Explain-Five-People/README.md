# Explain five people, then the model overall

In this activity, you will ask D14's boosted-trees model why it predicted what it did for five insured people, check that the pieces add up to each prediction, write one sentence for the pricing team, and then see which features matter most across the model.

**Time:** about 30 minutes in class, following along, with one sentence to write on your own · **Data:** `ml.insurance_groups` and `ml.ins_boosted` (D14 activity 01) → the model `ml.ins_explain` · **Starter:** `Unsolved/explain_five_people.sql`

## The story

On D14 the boosted trees predicted person E's yearly charges at about 43,500 dollars, close to her real 43,579. The pricing team trusts the number less than they would like, because nobody can say where it came from. A tree model has hundreds of questions inside it; you cannot read them. You can ask the model a simpler question: starting from its average prediction, how far did each of this person's facts push the prediction up or down?

## What you will learn

- To explain single predictions with `ML.EXPLAIN_PREDICT` and its `top_k_features` argument.
- To read the **baseline** (the model's expected output over the training rows) and the **attributions** (each feature's push), and to check that they add up to the prediction.
- To explain the model overall with `ML.GLOBAL_EXPLAIN`, which needs `ENABLE_GLOBAL_EXPLAIN = TRUE` when the model is trained, and to compare it with D14's `ML.FEATURE_IMPORTANCE`.
- That attributions describe what the model leaned on, not what causes high charges.

## Before you start

You need the view `ml.insurance_groups` and the model `ml.ins_boosted` from [D14 activity 01](../../D14/01-Evr-Same-Rows-Two-Models/README.md), blocks 1 and 4. Check: `SELECT COUNT(*) FROM ml.insurance_groups;` returns 1,338. If the view is missing, you also need `ml.insurance` (D11): upload [`insurance.csv`](../../../../../shared/datasets/ml_classics/insurance.csv) as `insurance` in `ml` with **Auto detect**, then run the insurance part of [`Resources/restart_d15.sql`](../Resources/restart_d15.sql), which rebuilds the view and both models used here.

Boosted trees are what Google calls *external* models: they are trained outside BigQuery. They do train in the sandbox, but slowly: 10 to 15 minutes or more. If `ml.ins_boosted` does not exist, start its training now (the insurance part of [`Resources/restart_d15.sql`](../Resources/restart_d15.sql)) and read on; if it is not ready when you need it, go to step 5 and use the prepared file, which carries the same explanations.

## Step 1 · Five people, and why the model priced them

The five validation people from D14 activity 02, found by their charges:

```sql
SELECT age, sex, bmi, children, smoker, region, ROUND(charges, 2) AS charges, split
FROM ml.insurance_groups
WHERE split = 'validation'
  AND ROUND(charges, 2) IN (4391.65, 10370.91, 13228.85, 17904.53, 43578.94)
ORDER BY charges;
```

| Person | Age | Sex | BMI | Children | Smoker | Region | Charges |
|---|---:|---|---:|---:|---|---|---:|
| A | 25 | female | 24.3 | 3 | no | southwest | 4,391.65 |
| B | 49 | female | 33.3 | 2 | no | northeast | 10,370.91 |
| C | 60 | female | 36.0 | 0 | no | northeast | 13,228.85 |
| D | 33 | male | 24.8 | 0 | yes | northeast | 17,904.53 |
| E | 57 | female | 31.2 | 0 | yes | northwest | 43,578.94 |

Now ask the model to explain each prediction:

```sql
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
```

`ML.EXPLAIN_PREDICT` is `ML.PREDICT` with explanations added. `top_k_features` is how many feature attributions come back per row, largest first by size; its default is 5, so 6 shows all six features. `top_feature_attributions` is an array: click a row to see each `feature` and its `attribution`. `charges` is not a feature of the model; it passes through to the output so you can see which person is which.

**What you should see:** five rows, A to E in order of charges. Computed outside BigQuery with the same settings: the baseline about 13,219 on every row; predictions about 8,069 · 10,350 · 15,262 · 17,717 · 43,526; for E the largest attribution is `smoker`, about +21,546. BigQuery's values may differ a little.

## Step 2 · The pieces add up

```sql
SELECT e.charges, a.feature, ROUND(a.attribution) AS attribution
FROM ML.EXPLAIN_PREDICT(MODEL ml.ins_boosted,
  (SELECT age, sex, bmi, children, smoker, region, charges
   FROM ml.insurance_groups
   WHERE split = 'validation'
     AND ROUND(charges, 2) IN (4391.65, 10370.91, 13228.85, 17904.53, 43578.94)),
  STRUCT(6 AS top_k_features)) AS e,
  UNNEST(e.top_feature_attributions) AS a
ORDER BY e.charges, ABS(a.attribution) DESC;
```

`UNNEST` (D10) turns each person's array into six rows, one per feature.

**What you should see:** 30 rows. For E, computed outside BigQuery: 13,219 (baseline) + 21,546 (smoker) + 4,611 (age) + 4,553 (BMI) − 512 (children) + 194 (region) − 85 (sex) = about 43,526, her prediction. The pieces add up exactly: for tree models BigQuery uses Tree SHAP, which Google's page lists as an exact method (`approximation_error` is 0).

Look at `smoker` across the five people: it pushes D's and E's predictions up and A's, B's and C's down. The same feature pushes in different directions for different people, because each push is measured against the average person.

## Step 3 · The model overall

`ML.GLOBAL_EXPLAIN` averages the size of each feature's attribution over many rows. Google's page: "You can only use ML.GLOBAL_EXPLAIN with models that are trained with the ENABLE_GLOBAL_EXPLAIN option set to TRUE." Its default is FALSE, and `ml.ins_boosted` was trained without it, so you train a copy with that one option added:

```sql
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
```

| Function | Measures | Unit |
|---|---|---|
| `ML.GLOBAL_EXPLAIN` | how far, on average, a feature moves a prediction | dollars |
| `ML.FEATURE_IMPORTANCE` (D14) | `importance_weight`: how many splits use the feature; `importance_gain`: how much those splits improved the fit | counts and gain |

**What you should see:** six rows from each function. Computed outside BigQuery as the average size of each attribution over the 268 validation people: smoker about 7,737 dollars, age about 3,316, BMI about 2,197, children about 818, region about 403, sex about 95. BigQuery computes its global explanation when the model is created, from "the local explanations of the evaluation data" (Google's page). This model has no evaluation rows: `NO_SPLIT` means "all input data is used as training data", and the pages do not say which rows are averaged then. So its sizes can differ from these; compare the order. D14's `ML.FEATURE_IMPORTANCE` put almost all the gain on `smoker`, with `bmi` and `age` used in the most splits.

Age moves predictions more than BMI, although BMI is used in more splits: the two functions answer different questions.

**Think:** the pricing team wants to drop `sex` from the model. What does the global table suggest, and what would you check before agreeing?

## Step 4 · Explain person D to the pricing team

Person D is 33, male, a smoker, with a BMI of 24.8. The model predicted about 17,717 dollars, well above the baseline but far below E. Using D's attributions from step 2, write one sentence a pricing manager can read: which feature pushed his price up most, which pulled it down most, and by about how much.

Write it down before you read the Solved file.

## Step 5 · If your trees are not ready: the prepared file

Download [`d15_insurance_explain.csv`](../Resources/fallback/d15_insurance_explain.csv) and upload it as `d15_explain` in `ml` (**⋮** → **Create table**, Upload, CSV, **Auto detect**). One row is one of the five people, with the model's prediction, the baseline and one contribution per feature, computed outside BigQuery with the same settings as `ml.ins_boosted`.

```sql
SELECT person, prediction, baseline, contrib_smoker, contrib_age, contrib_bmi,
       ROUND(baseline + contrib_age + contrib_bmi + contrib_children
             + contrib_sex + contrib_smoker + contrib_region, 2) AS rebuilt
FROM ml.d15_explain
ORDER BY person;
```

The same check as step 2: `rebuilt` (baseline plus the six contributions) equals `prediction` on every row. For one row per person and feature, as in step 2:

```sql
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
```

**What you should see:** five rows, then 30 rows, with the values described in steps 1 and 2.

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| 1 | 5 | ages **25**, **49**, **60**, **33**, **57** · charges **4,391.65** to **43,578.94** · all **validation** |
| 5 | 5 and 30 | one row per person, then six rows per person |

Steps 1 to 3 with the model depend on BigQuery's training run; their row counts are 5, 30 and 6.

## If something goes wrong

- **Fewer than five people:** the filter needs `ROUND(charges, 2)`; charges have more than two decimals.
- **`ML.GLOBAL_EXPLAIN` fails on `ml.ins_boosted`:** it was trained without `enable_global_explain = TRUE`. Use `ml.ins_explain`.
- **A message about billing when training `ml.ins_explain` or `ml.ins_boosted`:** use step 5.

## Hint

An attribution is measured from the baseline, not from zero. A negative attribution for `smoker` does not mean smoking lowers charges; it means this person's "no" brings the prediction below the average person's.

## Bonus

Run step 1's explanation with `STRUCT(2 AS top_k_features)`. Which two features does each person get? Is it the same two for everybody?

## References

Medical Cost Personal Datasets (Kaggle, `mirichoi0218/insurance`), from Brett Lantz, *Machine Learning with R* (Packt, 2013); course copy in [`shared/datasets/ml_classics`](../../../../../shared/datasets/ml_classics/README.md), taken 18 October 2026. BigQuery ML: [ML.EXPLAIN_PREDICT](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-explain-predict), [ML.GLOBAL_EXPLAIN](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-global-explain), [ML.FEATURE_IMPORTANCE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-importance), [Explainable AI overview](https://docs.cloud.google.com/bigquery/docs/xai-overview), [BigQuery ML pricing](https://cloud.google.com/bigquery/pricing#bqml) (built-in and external models), Google Cloud.
