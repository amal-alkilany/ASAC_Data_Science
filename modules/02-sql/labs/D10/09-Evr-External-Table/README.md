# Query a file where it lives

In this activity, you will create an **external table**: a table in BigQuery whose rows stay in a CSV file in Google Cloud Storage. BigQuery reads the file every time you query it.

**Time:** 13 minutes · **Data:** a public Google sample file, `gs://cloud-samples-data/bigquery/us-states/us-states.csv` (the 50 US states and their postal codes) · **Starter:** `Unsolved/external_table.sql`

## Native or external?

Every table you have used so far is **native**: when you uploaded the Nakheel CSVs, BigQuery copied the rows into its own storage. An **external table** stores only a definition: the file's address, its format and its columns. The rows stay in the file.

| | Native table | External table |
|---|---|---|
| Where the rows are | in BigQuery's storage | in a file in Cloud Storage (or Google Drive) |
| Storage size in **Details** | yes | none: BigQuery stores no rows |
| Change the file | upload again | the next query reads the new file |
| Speed | fast | slower: the file is read on every query |
| The same idea elsewhere | | Snowflake external tables over Amazon S3; Databricks and Microsoft Fabric reading files in a data lake |

Creating your own Cloud Storage bucket needs a Google Cloud billing account, which the free sandbox does not have. So today you read a file Google publishes for everyone.

## Instructions

1. **A dataset for files.** Datasets can be created with SQL too. In BigQuery, a dataset is what other databases call a schema:

    ```sql
    CREATE SCHEMA IF NOT EXISTS files
    OPTIONS (location = 'US');
    ```

    Refresh the explorer: `files` appears under your project.

2. **The external table.** Type and run:

    ```sql
    CREATE OR REPLACE EXTERNAL TABLE files.us_states (
      name STRING,
      post_abbr STRING
    )
    OPTIONS (
      format = 'CSV',
      uris = ['gs://cloud-samples-data/bigquery/us-states/us-states.csv'],
      skip_leading_rows = 1
    );
    ```

    - `EXTERNAL` means: store the definition, not the rows.
    - `uris` is the file's address. `gs://` is Cloud Storage, followed by the bucket (`cloud-samples-data`) and the path to the file.
    - `skip_leading_rows = 1` skips the header row, as **Header rows to skip** did in the upload guide.
    - The columns are written out because both are text, and auto-detect cannot find a header in an all-text file (the upload guide's section 6 explains why).

3. **Look at it in the explorer.** Open `files.us_states` → **Details**. The table type is **External**, the source URI is the `gs://` address, and there is no storage size.

4. **Query it like any table.** "Which states start with W?"

    ```sql
    SELECT name, post_abbr
    FROM files.us_states
    WHERE name LIKE 'W%'
    ORDER BY name;
    ```

    You should see 4 rows: Washington, West Virginia, Wisconsin, Wyoming. Before you run it, look at the bytes estimate: compare it with a native table's.

5. **Which file did each row come from?** External tables over Cloud Storage have a hidden column, `_FILE_NAME`:

    ```sql
    SELECT _FILE_NAME AS source_file,
           COUNT(*) AS states
    FROM files.us_states
    GROUP BY source_file;
    ```

    You should see 1 row: the `gs://` address, 50 states. When an external table points at many files (`uris` can end in `*`, for example one file per month), this column tells you which file each row came from.

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| 4 | 4 | Washington, West Virginia, Wisconsin, Wyoming |
| 5 | 1 | 50 states |

## If BigQuery refuses

If step 2 fails with an access or billing error in your sandbox project, use Google Drive instead, which needs no billing. Upload `shootouts.csv` from the [football dataset](../../../../../shared/datasets/intl_football/README.md) to your Google Drive; copy its link; in BigQuery, **Create table** → **Create table from:** Drive → paste the link → **File format:** CSV → **Table type:** External table → **Auto detect** → **Header rows to skip** 1. Allow BigQuery to see your Drive when it asks. Then query it: 694 rows.

## References

Google Cloud, [Introduction to external tables](https://cloud.google.com/bigquery/docs/external-tables) and [Create Cloud Storage external tables](https://cloud.google.com/bigquery/docs/external-data-cloud-storage). The sample file is published by Google in the public `cloud-samples-data` bucket and used in the BigQuery documentation.
