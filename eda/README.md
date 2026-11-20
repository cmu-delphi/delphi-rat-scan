# Exploratory data analysis

[`indicator_eda.qmd`](indicator_eda.qmd) analyzes candidate indicators on its own: characteristics, coverage, missingness, seasonality and revisions.

## Examples

NSSP COVID ED visits by state, from the command line:

```bash
quarto render eda/indicator_eda.qmd \
  -P source:nssp -P signal:pct_ed_visits_covid -P name:"NSSP: % ED Visits COVID" \
  -P geo_type:state -P start_day:2023-01-01 -P end_day:2025-12-31
```

NSSP COVID and flu ED visits together, from R:

```r
quarto::quarto_render("eda/indicator_eda.qmd", execute_params = list(
  source = "nssp",
  signal = c("pct_ed_visits_covid", "pct_ed_visits_influenza"),
  name = c("COVID-19 % ED", "Flu % ED"),
  geo_type = "state", start_day = "2023-01-01", end_day = "2025-12-31"
))
```

## Data

- **Epidata API**: set `source`, `signal` and `geo_type`. Only V5 sources are supported. `epidatr::epidata_meta()` lists them with their signals and geo types.
- **Local CSV**: set `input_csv` instead. Geographic level and time resolution are inferred from the data, and the source, signal and name params only override labels, which otherwise come from file and column names.

Columns the local CSV must or can contain:

| Column | Required | Description |
| --- | --- | --- |
| `geo_value`, `time_value`, `value` | Yes | Location, observation date and numeric value |
| `signal` | No | Signal identifier, when the file holds several signals (possibly from different sources) |
| `version` (or `issue`) | No | Issue date; enables the versioning section |
| `ci_lower`, `ci_upper` | No | Confidence bounds, drawn as bands in the location plot |
| `extra_keys` columns | No | Strata named by the `extra_keys` param, e.g. `age_group` |

## Params

| Param | Description | Default |
| --- | --- | --- |
| `source`, `signal` | Data source and signal(s); several signals must share the source | Required for API |
| `name` | Display label(s), one per signal | Signal name |
| `input_csv` | Local CSV, used instead of the API | `NULL` |
| `geo_type` | `state`, `county`, `msa`, … | Required for API; inferred for CSV |
| `start_day`, `end_day` | Date range (YYYY-MM-DD) | Full range |
| `extra_keys` | Extra key columns that split data into strata, e.g. `"age_group"` | None |
| `season_start_month` | First month of the epidemiological year (7 = July–June, flu convention) | `7` |
| `smooth_quantiles` | Smooth quantile trends; `FALSE` for signals smoothed at the source | `TRUE` |
| `show_geo_outliers` | Show the geographic outlier table | `TRUE` |
| `show_versioning` | Show the versioning summary; `FALSE` also skips the slow version-history fetch | `TRUE` |
| `max_locations_plot` | Max locations in faceted plots | `60` |
| `max_archive_locs` | Max locations fetched for version history | `60` |
| `min_archive_days` | Min days of version history for the revision analysis | `60` |
| `ci_band_limit_mult` | Drop confidence bands wider than this × the value range; `Inf` keeps all | `1` |
| `comparable_across_locations` | Levels comparable across locations (rate, %, per capita)? `FALSE` drops Location Variability; `NULL` infers | `NULL` |
| `value_type` | `cumulative`, `count`, `rate`, `percent`, `proportion` or `other`; only `cumulative` acts (drops Temporal Variability); `NULL` infers | `NULL` |
