# One tree, grown too deep

In this activity, you will train one decision tree twice, three questions deep and fifteen questions deep, and score each on the rows it learned from and on rows it never saw.

**Time:** about 14 minutes in class, following along · **Data:** `ml.insurance_groups` (activity 01) · **Starter:** `Unsolved/one_tree_too_deep.sql`

## The story

The depth-3 tree you used by hand gave only eight answers, and still predicted the five people well. If three questions are good, are fifteen better? A tree that keeps asking questions can eventually give each training person a leaf of their own. On D11 you saw what that does: a model that memorises its training rows looks perfect on them and worse on everyone else. Today you see it in a tree.

## What you will learn

- To train one decision tree in BigQuery ML, and what `max_iterations`, `learn_rate`, `l2_reg` and `max_tree_depth` do here.
- To read **overfitting** from two scores: training rows against validation rows.
- Why depth is a setting you choose, like k on D13 and the threshold on D12.

## Before you start

You need the view `ml.insurance_groups` from [activity 01](../01-Evr-Same-Rows-Two-Models/README.md), block 1. If it is missing, run that block first.

## Steps

1. **One tree, three questions deep (block 1).** BigQuery ML has no single-tree model, but a boosted-trees model with one round is one tree. Read the four options:

    | Option | Here | Why |
    |---|---|---|
    | `max_iterations = 1` | one round | boosting adds one tree per round; one round is one tree |
    | `learn_rate = 1` | keep it whole | boosting normally keeps only a share of each tree (part 3 of the class) |
    | `l2_reg = 0` | no shrinking | so each leaf predicts the plain average of its training rows, as in the tree you used by hand |
    | `max_tree_depth = 3` | three questions | the longest path from the top to a leaf |

    `max_iterations` and `learn_rate` are boosting settings, chosen here so that boosting reduces to a single tree; `l2_reg` and `max_tree_depth` are settings of each tree. You meet all four again with forests and boosting.

2. **The same tree, fifteen deep (block 2).** Only `max_tree_depth` changes.

3. **Seen against unseen (block 3).** Four rows: each tree on its training rows, then on the validation rows. Predict before you run: which row will be highest?

4. **How many answers can each tree give? (block 4).** A tree gives one answer per leaf. Count the different predictions on the training rows.

## Check yourself

| Block | Rows returned | One value to check |
|---|---:|---|
| 3 | 4 | depth 3: training R² ≈ 0.87, validation ≈ 0.84 · depth 15: training R² 1.00 (MAE ≈ 0), validation ≈ 0.73 |
| 4 | 2 | depth 3: 8 · depth 15: about 770, for 803 training people |

These values were computed outside BigQuery with the same settings. BigQuery may choose slightly different cut points (it groups values into bins to find them), so your validation scores can move by about 0.01.

**What it means.** The deep tree gave almost every training person a leaf of their own, so it reproduces their charges exactly: R² 1.00. On people it has not seen its R² is 0.73, the same as D11's straight line and well below the three-question tree. (Its MAE, about 2,860, is lower than the line's: it is right for most new people and badly wrong for a few, and R² squares the misses.) That gap between seen and unseen is overfitting: the deep tree memorised these 803 people, and the memory does not carry to new ones.

## If something goes wrong

- **The trees are still training, or `CREATE MODEL` stopped with an error:** use the fallback file from activity 01: its columns `pred_tree3` and `pred_tree15` hold these two trees' predictions, and the [Resources README](../Resources/README.md) scores them on training and validation rows.
- **`Option max_tree_depth must be ...`:** check the spelling; the options are not case-sensitive, but the underscores matter.

## Bonus

Train depth 5 and depth 8 the same way. Where does the validation score peak? (Computed outside BigQuery: depth 5 about 0.84, depth 8 about 0.81. The peak is near depth 3 to 6.)

## References

BigQuery ML: [CREATE MODEL for boosted trees](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-boosted-tree) (`MAX_ITERATIONS`, `LEARN_RATE`, `L2_REG`, `MAX_TREE_DEPTH`), Google Cloud. Data as in activity 01.
