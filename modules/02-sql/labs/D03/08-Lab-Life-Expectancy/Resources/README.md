# Life expectancy (Our World in Data)

Period life expectancy at birth for countries and world regions, one value per place per year, from 1950 to 2023. You use it in the D03 lab and the D04 practice questions.

Period life expectancy is the number of years a baby born in that year would live on average if the death rates at each age stayed as they were that year.

| Fact | Value |
|---|---|
| Source | Our World in Data, [Life expectancy](https://ourworldindata.org/grapher/life-expectancy) chart, "Full data" CSV download |
| Underlying data | From 1950, United Nations World Population Prospects 2024, for countries and regions alike (Our World in Data's processing notes). Earlier years combine other historical sources and are not in the course copy |
| Downloaded | 24 September 2026. The chart was last updated by Our World in Data on 22 October 2025 |
| Course copy | Rows from 1950 to 2023 only; columns renamed to lower case. No values changed |
| Rows | 19,314 |
| Licence | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) for Our World in Data's processing; the UN data is [CC BY 3.0 IGO](https://creativecommons.org/licenses/by/3.0/igo/) |

## File

`life_expectancy.csv`

| Column | Meaning |
|---|---|
| `entity` | Country, territory, region or group name, for example `Jordan`, `Hong Kong`, `Africa`, `High-income countries` |
| `code` | Country code where one exists, usually the three-letter ISO code, for example `JOR`. Our World in Data gives some regions and groups its own codes starting `OWID_`. Some rows have no code at all |
| `year` | Calendar year |
| `life_expectancy` | Period life expectancy at birth, in years |

Upload it into a BigQuery dataset named `owid` as a table named `life_expectancy_data`. Do not name the table `life_expectancy`: a table with the same name as one of its columns makes BigQuery read `life_expectancy` as the whole row (see the BigQuery note in the lab README). Follow the steps in the [lab README](../README.md).

## Why 1950 onward

The full download goes back to 1543 for a few places and mixes several historical sources before 1950. From 1950 every country and region comes from one source, the UN, so every row in the course copy is measured the same way and carries one clear licence.

## Attribution

Please keep this with any copy of the file:

> Riley (2005); Zijdeman et al. (2015); HMD (2025); UN WPP (2024) – with major processing by Our World in Data. "Life expectancy – Riley; Zijdeman et al.; HMD; UN WPP – Long-run data" [dataset]. Retrieved from https://ourworldindata.org/grapher/life-expectancy on 24 September 2026. Course copy: rows from 1950 to 2023, which Our World in Data takes from United Nations, World Population Prospects 2024.
