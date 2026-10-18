# D11 resources

Everything today's activities and labs read, and what to do when something goes wrong.

## The data

All four files are in [`shared/datasets/ml_classics`](../../../../../shared/datasets/ml_classics/README.md), with upload steps, row counts to check and sources.

| File | Table | Used in |
|---|---|---|
| `salary_data.csv` | `ml.salary` | activity 02, lab 06 |
| `insurance.csv` | `ml.insurance` | activities 03 and 04, lab 06 |
| `mpg.csv` | `ml.cars` (and the view `ml.cars_clean`) | labs 05, 06, 07 |
| Nakheel `orders` and `customers` (from D04) | `nakheel.*` | lab 08 (optional) |

Create the dataset once: `CREATE SCHEMA IF NOT EXISTS ml OPTIONS (location = 'US');`

## The order of the after-class labs

Lab 05 creates `ml.cars_clean` and `ml.cars_random`, which labs 06 and 07 read. Do 05 first. Lab 08 is optional self-study and needs only the `nakheel` tables.

## If something goes wrong

- **`Not found: Table ...ml.salary` (or `insurance`, `cars`):** the upload went to another dataset or name. Upload again into `ml` with the table name above.
- **`Dataset ml was not found in location US`:** `ml` was created in another location. Delete it and run the `CREATE SCHEMA` above.
- **`CREATE MODEL` takes a long time:** the sandbox queues training jobs. Wait two minutes before doing anything else.
- **Your scores differ from a classmate's:** every `RANDOM` split holds aside different rows. The READMEs give ranges.
- **`Unrecognized name`:** open the table's **Schema** tab and use the names it shows.
