# Lab 05 · Three classes: which penguin is it?

In this self-guided lab, you will train a logistic regression that chooses between three classes instead of two, read its three probabilities, and read a three-by-three confusion matrix. The data is one of BigQuery's public tables, so there is nothing to upload.

**When:** after class, about 30 minutes, at your own pace. Not submitted. · **Data:** `bigquery-public-data.ml_datasets.penguins` · **SQL:** `Solved/three_classes.sql`

## How to work through this lab

Run each query, compare with **What you should see**, and answer **Think** in one line. Your `ml` dataset must be in the US location (it is, if you created it in D11), because the public table is there.

## The data

344 penguins from three islands near Palmer Station, Antarctica. One row is one penguin. The label is `species`: Adelie, Chinstrap or Gentoo. Features: `island`, `culmen_length_mm` and `culmen_depth_mm` (the bill), `flipper_length_mm`, `body_mass_g`, `sex`.

## Step 1 · Look first

```sql
SELECT species, COUNT(*) AS penguin_count,
       ROUND(AVG(flipper_length_mm), 1) AS avg_flipper,
       ROUND(AVG(body_mass_g)) AS avg_mass
FROM `bigquery-public-data.ml_datasets.penguins`
GROUP BY species;

SELECT COUNTIF(body_mass_g IS NULL) AS no_mass, COUNTIF(sex IS NULL) AS no_sex
FROM `bigquery-public-data.ml_datasets.penguins`;
```

**What you should see:** three species of different sizes (Gentoo the largest, with the longest flippers), and a few penguins with missing measurements. BigQuery fills a missing number with the column's average when it trains, and treats a missing text value as its own category.

**Think:** which single measurement would you use to tell a Gentoo from the other two?

## Step 2 · Train: the same model type, three classes

```sql
CREATE OR REPLACE MODEL ml.penguin_species
OPTIONS (model_type = 'LOGISTIC_REG', input_label_cols = ['species'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2) AS
SELECT island, culmen_length_mm, culmen_depth_mm, flipper_length_mm, body_mass_g, sex, species
FROM `bigquery-public-data.ml_datasets.penguins`;
```

Nothing new in the statement. Because `species` has three values, BigQuery trains a **multiclass** logistic regression. With 344 rows (fewer than 500), the explicit split matters, as in D11's lab 05.

## Step 3 · Score it

```sql
SELECT ROUND(accuracy, 3) AS accuracy, ROUND(precision, 3) AS precision,
       ROUND(recall, 3) AS recall, ROUND(roc_auc, 3) AS roc_auc
FROM ML.EVALUATE(MODEL ml.penguin_species);
```

**What you should see:** very high scores, accuracy close to 1. With three classes, precision and recall are averaged over the classes (each class computed on its own, then averaged).

**Think:** after D12's leak lesson, a near-perfect score is a reason to look closer. Is anything here a leak, or are penguin species simply easy to tell apart by size and bill?

## Step 4 · A three-by-three matrix

```sql
SELECT * FROM ML.CONFUSION_MATRIX(MODEL ml.penguin_species);
```

**What you should see:** three rows (what the penguin really was) and three count columns (what the model said). Almost every count sits on the diagonal. The column names look odd: BigQuery turns each species name into a valid column name.

## Step 5 · Three probabilities per penguin

```sql
SELECT species,
       predicted_species,
       ARRAY(SELECT AS STRUCT label, ROUND(prob, 3) AS prob
             FROM UNNEST(predicted_species_probs) ORDER BY prob DESC) AS probs
FROM ML.PREDICT(MODEL ml.penguin_species,
  (SELECT * FROM `bigquery-public-data.ml_datasets.penguins` LIMIT 5));
```

**What you should see:** for each penguin, three probabilities that add up to 1, sorted from the most likely. `predicted_species` is the one with the highest probability: with three classes there is no single threshold to move.

## Step 6 · Which features does it lean on?

```sql
CREATE OR REPLACE MODEL ml.penguin_explained
OPTIONS (model_type = 'LOGISTIC_REG', input_label_cols = ['species'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         enable_global_explain = TRUE) AS
SELECT island, culmen_length_mm, culmen_depth_mm, flipper_length_mm, body_mass_g, sex, species
FROM `bigquery-public-data.ml_datasets.penguins`;

SELECT * FROM ML.GLOBAL_EXPLAIN(MODEL ml.penguin_explained);
```

**What you should see:** the bill and flipper measurements near the top; `sex` near the bottom. Compare with your answer to step 1.

## What you saw

| Question | Two classes (D12) | Three classes (this lab) |
|---|---|---|
| What does `ML.PREDICT` give? | | |
| How is Yes or No decided? | a threshold | |
| Shape of the confusion matrix | 2 × 2 | |

## References

Palmer penguins (Gorman, Williams and Fraser, 2014), as BigQuery's public table `bigquery-public-data.ml_datasets.penguins`. BigQuery ML: [CREATE MODEL for logistic regression](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-glm), [ML.GLOBAL_EXPLAIN](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-global-explain), Google Cloud.
