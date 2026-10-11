# Load the Assignment 1 data

In this activity, you will create the `football` dataset and upload the three Assignment 1 files, so that you leave class with the data loaded and checked.

**Time:** 12 minutes · **Data:** [International football results](../../../../../shared/datasets/intl_football/README.md) (`matches.csv`, `goals.csv`, `shootouts.csv`) · **Starter:** `Unsolved/check_football.sql`

## Instructions

1. **Download the three files** from the [dataset folder](../../../../../shared/datasets/intl_football/README.md): `matches.csv` (4 MB), `goals.csv` (2.4 MB) and `shootouts.csv`.

2. **Create the dataset.** Next to your project, **⋮** → **Create dataset**. **Dataset ID** `football`. **Location type** **Multi-region**, **US**, the same as `nakheel`. **Create dataset**.

3. **Upload each file**, as in [Upload a CSV to BigQuery](../../../resources/upload-a-csv-to-bigquery.md): next to `football`, **⋮** → **Create table** → **Upload** → the file → **File format** CSV → **Table** `matches`, `goals` or `shootouts` → **Auto detect** ticked → **Advanced options** → **Header rows to skip** `1` → **Create table**.

4. **Check the types.** Open `football.matches` → **Schema**. `match_date` must be `DATE` and `neutral` `BOOLEAN`. Open `football.goals`: `own_goal` and `penalty` must be `BOOLEAN`.

5. **Check the rows.** Run the three counts in the starter.

## Check yourself

| Check | Rows returned | One value to check |
|---|---:|---|
| matches | 1 | 49,807 |
| goals | 1 | 47,914 |
| shootouts | 1 | 694 |

If a count is lower, the upload stopped early or skipped rows: delete the table and upload it again. If `match_date` is `STRING`, the header was loaded as data: check **Header rows to skip**.

## References

Mart Jürisoo, [International football results from 1872 to 2026](https://github.com/martj42/international_results), CC0 1.0. Course copy taken 9 October 2026; see [the dataset README](../../../../../shared/datasets/intl_football/README.md).
