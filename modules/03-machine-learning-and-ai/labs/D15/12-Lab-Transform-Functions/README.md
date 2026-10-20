# Lab 12 · TRANSFORM and the preprocessing functions

In this self-guided lab, you will put BigQuery ML's preprocessing functions inside a `TRANSFORM` clause, look at the features they make with `ML.TRANSFORM` and the columns they start from with `ML.FEATURE_INFO`, and compare the model from class with one trained on D14 lab 10's leaky bands.

**When:** after class, about 50 minutes, at your own pace. Not submitted. · **Data:** `ml.insurance_groups` (D14 activity 01), `ml.ins_transform` (activity 08) · **SQL:** `Unsolved/transform_functions.sql` to run step by step, `Solved/transform_functions.sql`

## The story

In class, `TRANSFORM` fixed one leak: BMI bands cut over all 1,338 people. The pricing team's analyst now wants to scale and band other columns the same way, and asks two things: which functions need the training statistics (and so belong inside `TRANSFORM`), and does fixing the leak change the score? This lab answers both on the insurance data, with linear models that train in every sandbox.

## What you will learn

- Which preprocessing functions compute statistics from rows (analytic, with `OVER ()`) and which do not.
- To use `ML.QUANTILE_BUCKETIZE`, `ML.BUCKETIZE`, the scalers, `ML.FEATURE_CROSS` and `ML.POLYNOMIAL_EXPAND` inside `TRANSFORM`, and to see their output with `ML.TRANSFORM`.
- To compare a leaky model with a `TRANSFORM` model on the same validation people.
- The rules of the `TRANSFORM` clause, and what `ML.FEATURE_INFO` reports for a model that has one.

## Before you start

You need `ml.insurance_groups` from [D14 activity 01](../../D14/01-Evr-Same-Rows-Two-Models/README.md) (check: `SELECT COUNT(*) FROM ml.insurance_groups;` returns 1,338) and `ml.ins_transform` from [activity 08](../08-Evr-Transform-And-Save/README.md), step 1. [`Resources/restart_d15.sql`](../Resources/restart_d15.sql) rebuilds both. Every model here is a `LINEAR_REG`, a built-in model, so it trains in a sandbox.

Work like the other labs: read the step, run its SQL, compare with **What you should see**, and answer **Think** in one line. The cut points and counts in plain SQL are exact; BigQuery's `ML.QUANTILE_BUCKETIZE` computes its own quantiles, which can differ a little.

## Step 1 · The leak, in numbers

```sql
SELECT DISTINCT 'all 1,338 people' AS rows_used,
       ROUND(PERCENTILE_CONT(bmi, 0.25) OVER (), 2) AS cut_1,
       ROUND(PERCENTILE_CONT(bmi, 0.5) OVER (), 2) AS cut_2,
       ROUND(PERCENTILE_CONT(bmi, 0.75) OVER (), 2) AS cut_3
FROM ml.insurance_groups
UNION ALL
SELECT DISTINCT 'the 803 training people',
       ROUND(PERCENTILE_CONT(bmi, 0.25) OVER (), 2),
       ROUND(PERCENTILE_CONT(bmi, 0.5) OVER (), 2),
       ROUND(PERCENTILE_CONT(bmi, 0.75) OVER (), 2)
FROM ml.insurance_groups
WHERE split = 'train';
```

The same query as activity 08: the cut points D14 lab 10 used (all rows) against the ones the training rows alone give.

**What you should see:** all rows 26.3, 30.4, 34.69; training rows 26.27, 30.25, 34.36. With the training cut points, 5 validation people and 7 test people land in a different band (activity 08, step 1).

## Step 2 · What ML.QUANTILE_BUCKETIZE returns on its own

```sql
SELECT bmi_quarter, MIN(bmi) AS lowest, MAX(bmi) AS highest, COUNT(*) AS people
FROM (
  SELECT bmi, ML.QUANTILE_BUCKETIZE(bmi, 4, 'bucket_ranges') OVER () AS bmi_quarter
  FROM ml.insurance_groups
  WHERE split = 'train'
)
GROUP BY bmi_quarter
ORDER BY lowest;
```

The page's syntax: `ML.QUANTILE_BUCKETIZE(numerical_expression, num_buckets [, output_format]) OVER()`. `num_buckets` is how many groups of about equal size. `output_format` is `'bucket_names'` (the default: `bin_1`, `bin_2` …), `'bucket_ranges'` (for example `[26.27, 30.25)`) or `'bucket_ranges_json'`. The empty `OVER ()` is required: it is an analytic function, and it looks at every row the query reads. This query reads the training rows only.

**What you should see:** 4 rows, about 200 people each, with ranges whose edges are BigQuery's cut points. Compare them with step 1's training cut points.

## Step 3 · Inside TRANSFORM, and what the model sees

```sql
SELECT bmi_band, COUNT(*) AS people
FROM ML.TRANSFORM(MODEL ml.ins_transform,
  (SELECT * FROM ml.insurance_groups WHERE split = 'validation'))
GROUP BY bmi_band
ORDER BY bmi_band;
```

`ML.TRANSFORM` runs a model's `TRANSFORM` clause on the rows you pass. Its page: "ML.TRANSFORM returns the columns specified in the model's TRANSFORM clause", so you get the features the model would see (and the label, because the clause lists `charges`), not the raw `bmi`. The syntax is `ML.TRANSFORM(MODEL model_name, { TABLE table_name | (query) })`; the input's column names must match the ones the clause reads, and a model trained without `TRANSFORM` returns an error. Here: the 268 validation people, banded with the cut points `ml.ins_transform` computed from the training rows. Google's guide: "When you use ML analytic functions inside the TRANSFORM clause during training, the same statistics are automatically applied to the input in prediction." The validation rows do not move the cut points.

The same bands in plain SQL, with the exact training cut points from step 1:

```sql
WITH cuts_train AS (
  SELECT DISTINCT PERCENTILE_CONT(bmi, 0.25) OVER () AS c1,
         PERCENTILE_CONT(bmi, 0.5) OVER () AS c2,
         PERCENTILE_CONT(bmi, 0.75) OVER () AS c3
  FROM ml.insurance_groups
  WHERE split = 'train'
)
SELECT CONCAT('bin_', CAST(1 + IF(g.bmi >= t.c1, 1, 0) + IF(g.bmi >= t.c2, 1, 0) + IF(g.bmi >= t.c3, 1, 0) AS STRING)) AS bmi_band,
       COUNT(*) AS people
FROM ml.insurance_groups AS g
CROSS JOIN cuts_train AS t
WHERE g.split = 'validation'
GROUP BY bmi_band
ORDER BY bmi_band;
```

**What you should see:** both queries return 4 rows. The plain-SQL counts are 73, 56, 63 and 76; BigQuery's will match or differ by a person or two where its cut points differ.

## Step 4 · The leaky way, for comparison

```sql
CREATE OR REPLACE VIEW ml.insurance_banded_all AS
SELECT *, ML.QUANTILE_BUCKETIZE(bmi, 4) OVER () AS bmi_band
FROM ml.insurance_groups;

CREATE OR REPLACE MODEL ml.ins_leaky_band
OPTIONS (model_type = 'LINEAR_REG',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT bmi_band, age, sex, children, smoker, region, charges
FROM ml.insurance_banded_all
WHERE split = 'train';

SELECT 'bands over all rows (leaky)' AS model,
       ROUND(r2_score, 3) AS validation_r2, ROUND(mean_absolute_error) AS validation_mae
FROM ML.EVALUATE(MODEL ml.ins_leaky_band,
  (SELECT * FROM ml.insurance_banded_all WHERE split = 'validation'))
UNION ALL
SELECT 'bands from training rows (TRANSFORM)',
       ROUND(r2_score, 3), ROUND(mean_absolute_error)
FROM ML.EVALUATE(MODEL ml.ins_transform,
  (SELECT * FROM ml.insurance_groups WHERE split = 'validation'));
```

The view does what D14 lab 10 did: one set of bands over all 1,338 people, test rows included. The two models differ only in where the cut points came from.

**What you should see:** 2 rows with close scores: only a handful of people change band. The lesson is not the size of the gap on this table; it is that the leaky model's validation score used information from the validation and test people, so it is not an honest preview, however small the effect.

**Think:** on which kind of data would the leak matter more: a small table or a big one, a column with a few extreme values or an even spread?

## Step 5 · ML.BUCKETIZE: cut points you choose

```sql
SELECT ML.BUCKETIZE(2.5, [1, 2, 3]) AS default_names,
       ML.BUCKETIZE(2.5, [1, 2, 3], TRUE) AS without_outer_buckets,
       ML.BUCKETIZE(2.5, [1, 2, 3], FALSE, 'bucket_ranges') AS as_range;
```

`ML.BUCKETIZE(numerical_expression, array_split_points [, exclude_boundaries] [, output_format])` is a scalar function: no `OVER ()`, no statistics. The split points must be finite and ascending; three points make four buckets. `exclude_boundaries` (default FALSE) drops the two outer buckets. `output_format` takes the same three values as in step 2.

**What you should see:** `bin_3`, `bin_2` and `[2, 3)`, the page's own example. Now in a model:

```sql
CREATE OR REPLACE MODEL ml.ins_fixed_bands
TRANSFORM (ML.BUCKETIZE(age, [30, 45, 60]) AS age_band,
           ML.BUCKETIZE(bmi, [30]) AS bmi_30,
           sex, children, smoker, region, charges)
OPTIONS (model_type = 'LINEAR_REG',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

SELECT CASE WHEN age < 30 THEN 'bin_1' WHEN age < 45 THEN 'bin_2' WHEN age < 60 THEN 'bin_3' ELSE 'bin_4' END AS age_band,
       COUNT(*) AS people
FROM ml.insurance_groups
WHERE split = 'train'
GROUP BY age_band
ORDER BY age_band;
```

Cut points you write yourself cannot leak: they come from you, not from the rows. They do not have to sit inside `TRANSFORM`, but putting them there means a prediction query passes the raw `age` and `bmi` and nobody has to repeat the cut points. The plain-SQL query shows the bands the model trains on.

**What you should see:** the model trains; the band counts are 247, 233, 261 and 62 (D14 lab 10's counts).

## Step 6 · The scalers

```sql
CREATE OR REPLACE MODEL ml.ins_scaled
TRANSFORM (ML.STANDARD_SCALER(bmi) OVER () AS bmi_standard,
           ML.MIN_MAX_SCALER(age) OVER () AS age_min_max,
           ML.MAX_ABS_SCALER(children) OVER () AS children_max_abs,
           sex, smoker, region, charges)
OPTIONS (model_type = 'LINEAR_REG',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

SELECT 'train' AS rows_scaled,
       ROUND(AVG(bmi_standard), 3) AS avg_bmi_standard,
       ROUND(MIN(age_min_max), 3) AS min_age_scaled, ROUND(MAX(age_min_max), 3) AS max_age_scaled
FROM ML.TRANSFORM(MODEL ml.ins_scaled,
  (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
UNION ALL
SELECT 'validation',
       ROUND(AVG(bmi_standard), 3), ROUND(MIN(age_min_max), 3), ROUND(MAX(age_min_max), 3)
FROM ML.TRANSFORM(MODEL ml.ins_scaled,
  (SELECT * FROM ml.insurance_groups WHERE split = 'validation'));
```

The scalers put numbers on a common scale, each from statistics of the training rows, so each is written `function(column) OVER ()` with an empty `OVER ()`, and each returns a FLOAT64:

| Function | What it does (Google's page) | Arguments |
|---|---|---|
| `ML.STANDARD_SCALER` | a z-score: subtract the mean, divide by the standard deviation | the column only |
| `ML.MIN_MAX_SCALER` | maps the training range to [0, 1]; at prediction, values outside it are capped at 0 and 1 | the column only |
| `ML.MAX_ABS_SCALER` | divides by the largest absolute value, so values fall in [-1, 1]; it does not shift or centre | the column only |
| `ML.ROBUST_SCALER` | subtracts the median and divides by the quantile range, so outliers matter less | the column, then optional `quantile_range` (default `[25, 75]`), `with_median` (default TRUE), `with_quantile_range` (default TRUE) |

Each page says the same about `TRANSFORM`, for example "When used in the TRANSFORM clause, the standard deviation and mean values calculated to standardize the expression are automatically used in prediction." Try `ML.ROBUST_SCALER(bmi) OVER () AS bmi_robust` in place of the standard scaler.

Now the statistics themselves, in plain SQL:

```sql
SELECT split, ROUND(AVG(bmi), 2) AS avg_bmi, MIN(age) AS youngest, MAX(age) AS oldest
FROM ml.insurance_groups
GROUP BY split
ORDER BY split;
```

**What you should see:** on the training rows, `avg_bmi_standard` is 0 and the scaled age runs from 0 to 1, by construction. On the validation rows the average is not 0: their BMI averages 30.72, the training rows 30.52, and the model kept the training mean. That is `TRANSFORM` working as intended.

## Step 7 · Crosses and powers

```sql
CREATE OR REPLACE MODEL ml.ins_cross_poly
TRANSFORM (ML.FEATURE_CROSS(STRUCT(smoker, region)) AS smoker_region,
           ML.POLYNOMIAL_EXPAND(STRUCT(age, bmi), 2) AS age_bmi_poly,
           sex, children, smoker, charges)
OPTIONS (model_type = 'LINEAR_REG',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

SELECT *
FROM ML.TRANSFORM(MODEL ml.ins_cross_poly,
  (SELECT * FROM ml.insurance_groups WHERE split = 'validation'))
LIMIT 3;
```

D14 lab 10 built these in the `SELECT`. Both are scalar (no statistics, no `OVER ()`), so they cannot leak; inside `TRANSFORM` they simply travel with the model. `ML.FEATURE_CROSS(struct_categorical_features [, degree])` crosses text columns (degree 2 to 4, default 2) and leaves out the original columns; `ML.POLYNOMIAL_EXPAND(struct_numerical_features [, degree])` multiplies number columns (degree 1 to 4, default 2) and keeps the originals, so `age_bmi_poly` holds `age`, `age_age`, `age_bmi`, `bmi` and `bmi_bmi`. Both return a STRUCT whose field names join the original column names. `ML.FEATURE_CROSS` is the general CREATE MODEL page's own `TRANSFORM` example.

**What you should see:** 3 rows, with `smoker_region` and `age_bmi_poly` as STRUCT columns (open a row to see their fields).

## Step 8 · The rest of the list

Google's manual preprocessing guide lists these functions. Steps 2 to 7 used the ones marked; the rest follow the same pattern inside `TRANSFORM`, and each has its own page.

| Group | Function | In this lab |
|---|---|---|
| General | `ML.IMPUTER` | |
| Numerical | `ML.BUCKETIZE` | step 5 |
| Numerical | `ML.MAX_ABS_SCALER` | step 6 |
| Numerical | `ML.MIN_MAX_SCALER` | step 6 |
| Numerical | `ML.NORMALIZER` | |
| Numerical | `ML.POLYNOMIAL_EXPAND` | step 7 |
| Numerical | `ML.QUANTILE_BUCKETIZE` | steps 2 to 4 |
| Numerical | `ML.ROBUST_SCALER` | step 6 (to try) |
| Numerical | `ML.STANDARD_SCALER` | step 6 |
| Categorical | `ML.FEATURE_CROSS` | step 7 |
| Categorical | `ML.HASH_BUCKETIZE` | |
| Categorical | `ML.LABEL_ENCODER` | |
| Categorical | `ML.MULTI_HOT_ENCODER` | |
| Categorical | `ML.ONE_HOT_ENCODER` | |
| Text | `ML.NGRAMS`, `ML.BAG_OF_WORDS`, `ML.TF_IDF` | |

The guide's rule for the analytic ones: "You must always use an empty OVER() clause with ML analytic functions."

## Step 9 · The rules of TRANSFORM

From the CREATE MODEL page:

- "When the TRANSFORM clause is present, only output columns from the TRANSFORM clause are used in training." A column the `SELECT` returns but `TRANSFORM` leaves out is ignored.
- Not allowed inside `TRANSFORM`: aggregate functions, analytic functions other than BigQuery ML's, user-defined functions, subqueries, and unnamed columns ("a + b as c is allowed, while a + b isn't").
- The label (here `charges`) must appear untransformed and without an alias.
- `*`, `* EXCEPT (…)` and `* REPLACE (…)` are allowed, so `TRANSFORM (* EXCEPT (bmi), ML.QUANTILE_BUCKETIZE(bmi, 4) OVER () AS bmi_band)` is the class model in one line.
- At prediction, pass the original columns the clause uses; the dropped ones are not needed.
- `ML.FEATURE_IMPORTANCE` on a tree model with `TRANSFORM` reports the columns before the transform; `ML.EXPLAIN_PREDICT` accepts only input columns that appear in the clause; and an ARIMA_PLUS model with custom holidays cannot use `TRANSFORM` (lab 13).

## Step 10 · ML.FEATURE_INFO: the columns before the transform

Step 9's last rule said `ML.FEATURE_IMPORTANCE` reports the columns before the transform. `ML.FEATURE_INFO` does the same, and it works on any model, the linear ones here included. It lists what the model was given, one row per input column, with `min`, `max`, `mean`, `median`, `stddev`, `category_count` and `null_count`. Its page: "If you used the TRANSFORM clause in the CREATE MODEL statement that created the model, ML.FEATURE_INFO outputs the information of the pre-transform columns from the query_statement argument."

```sql
SELECT input, min, max, ROUND(mean, 2) AS mean, median, category_count, null_count
FROM ML.FEATURE_INFO(MODEL ml.ins_scaled);

SELECT *
FROM ML.TRANSFORM(MODEL ml.ins_scaled,
  (SELECT * FROM ml.insurance_groups WHERE split = 'train'))
LIMIT 3;
```

The same statistics in plain SQL, from the 803 training rows `ml.ins_scaled` learned from:

```sql
SELECT 'age' AS input, MIN(age) AS min_value, MAX(age) AS max_value, ROUND(AVG(age), 2) AS mean_value,
       NULL AS categories
FROM ml.insurance_groups WHERE split = 'train'
UNION ALL
SELECT 'bmi', MIN(bmi), MAX(bmi), ROUND(AVG(bmi), 2), NULL
FROM ml.insurance_groups WHERE split = 'train'
UNION ALL
SELECT 'children', MIN(children), MAX(children), ROUND(AVG(children), 2), NULL
FROM ml.insurance_groups WHERE split = 'train'
UNION ALL
SELECT 'sex', NULL, NULL, NULL, COUNT(DISTINCT sex)
FROM ml.insurance_groups WHERE split = 'train'
UNION ALL
SELECT 'smoker', NULL, NULL, NULL, COUNT(DISTINCT smoker)
FROM ml.insurance_groups WHERE split = 'train'
UNION ALL
SELECT 'region', NULL, NULL, NULL, COUNT(DISTINCT region)
FROM ml.insurance_groups WHERE split = 'train';
```

**What you should see:** `ML.FEATURE_INFO` returns the raw columns `age`, `bmi`, `children`, `sex`, `smoker` and `region`, not `bmi_standard`, `age_min_max` or `children_max_abs`; `ML.TRANSFORM` returns those three, with `sex`, `smoker`, `region` and `charges`. The plain-SQL query gives 6 rows: age 18 to 64, mean 39.29 (median 39); BMI 16.815 to 53.13, mean 30.52 (median 30.25); children 0 to 5, mean 1.09 (median 1); 2 values of `sex`, 2 of `smoker` and 4 regions, with `null_count` 0 everywhere. `ML.FEATURE_INFO`'s numbers should match: the model saw only the training rows, because the `SELECT` kept `split = 'train'`.

**Think:** you inherit a model and want to know which columns a prediction query must pass. Which function tells you, `ML.FEATURE_INFO` or `ML.TRANSFORM`?

## More practice (not checked, not submitted)

- Train `ml.ins_transform` again with `TRANSFORM (* EXCEPT (bmi), ML.QUANTILE_BUCKETIZE(bmi, 4) OVER () AS bmi_band)` and check with step 3 that it gives the same bands. What did `*` pick up that the class model did not have?
- Add `ML.QUANTILE_BUCKETIZE(age, 5) OVER () AS age_band` to the class model and compare validation scores with step 4's query.

## What you saw

| Model | Where the statistics came from | Validation R² |
|---|---|---:|
| `ml.ins_leaky_band` | all 1,338 people | |
| `ml.ins_transform` | the 803 training people | |
| `ml.ins_fixed_bands` | you (no statistics) | |
| `ml.ins_scaled` | the 803 training people | |

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| 1 | 2 | all rows **26.3**, **30.4**, **34.69** · training **26.27**, **30.25**, **34.36** |
| 3 | 4 | validation people by training bands: **73**, **56**, **63**, **76** |
| 5 | 4 | training people by age band: **247**, **233**, **261**, **62** |
| 6 | 3 | average BMI: training **30.52**, validation **30.72** · ages **18** to **64** |
| 10 | 6 | age **18** to **64**, mean **39.29** · BMI **16.815** to **53.13**, mean **30.52** · children mean **1.09** · categories **2**, **2**, **4** |

## Hint

If a function needs to look at many rows to do its job (a mean, a quantile, a largest value), it takes `OVER ()` and belongs inside `TRANSFORM`. If it works on one row at a time with values you give it, it does not need the training rows.

## Bonus

`ML.QUANTILE_BUCKETIZE(bmi, 4, 'bucket_ranges_json') OVER ()` returns the ranges as JSON text. Run step 2 with it: what does the lowest bucket's start look like?

## References

Medical Cost Personal Datasets (Kaggle, `mirichoi0218/insurance`), from Brett Lantz, *Machine Learning with R* (Packt, 2013); course copy in [`shared/datasets/ml_classics`](../../../../../shared/datasets/ml_classics/README.md), taken 18 October 2026. BigQuery ML: [the TRANSFORM clause](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create#transform), [manual preprocessing](https://docs.cloud.google.com/bigquery/docs/manual-preprocessing), [ML.TRANSFORM](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-transform), [ML.FEATURE_INFO](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-feature), [ML.QUANTILE_BUCKETIZE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-quantile-bucketize), [ML.BUCKETIZE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-bucketize), [ML.STANDARD_SCALER](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-standard-scaler), [ML.MIN_MAX_SCALER](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-min-max-scaler), [ML.MAX_ABS_SCALER](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-max-abs-scaler), [`ML.ROBUST_SCALER`](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-robust-scaler), [ML.FEATURE_CROSS](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-feature-cross), [ML.POLYNOMIAL_EXPAND](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-polynomial-expand), Google Cloud. All pages read 19 October 2026.
