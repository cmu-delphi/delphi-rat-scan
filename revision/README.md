# Revision analysis

[`indicator_revision.qmd`](indicator_revision.qmd) uses one signal's version history to check whether first reports are biased, how soon values stabilize near their latest value, and whether that differs by location, reference date (epi season), value size or initial reporting lag.

## Example

Revisions of NHSN weekly COVID admissions by state, from the command line or from R:

```bash
quarto render revision/indicator_revision.qmd \
  -P source:nhsn -P signal:confirmed_admissions_covid_ew \
  -P signal_name:"NHSN: Confirmed COVID Admissions" \
  -P geo_type:state -P start_day:2020-01-01 -P end_day:2025-12-31
```

```r
quarto::quarto_render("revision/indicator_revision.qmd", execute_params = list(
  source = "nhsn", signal = "confirmed_admissions_covid_ew",
  signal_name = "NHSN: Confirmed COVID Admissions",
  geo_type = "state", start_day = "2020-01-01", end_day = "2025-12-31"
))
```

## Data

There is no default signal: give an API signal or local data.

- **Epidata API**: set `source`, `signal` and `geo_type`; only values with `fill_method = "source"` are fetched. Only V5 sources are supported; `epidatr::epidata_meta()` lists them with their signals and geo types.
- **Local files**: set `input_dir` to a CSV, a Parquet file or a directory of Parquet files.

Columns the local data must or can contain:

| Column | Required | Description |
| --- | --- | --- |
| `geo_value`, `time_value`, `value` | Yes | Location, observation date and numeric value |
| `version` (or `issue`) | Yes | Issue date of each value; without it the notebook stops with an error |

## Params

| Param | Description | Default |
| --- | --- | --- |
| `source`, `signal` | Epidata V5 source and signal | Required for API |
| `signal_name` | Display label | Required |
| `input_dir` | Local version history, used instead of the API | `NULL` |
| `geo_type` | `state`, `county`, `hhs`, … | `"state"` |
| `start_day`, `end_day` | Range of `time_value` (YYYY-MM-DD) | Full range |
| `max_locations_plot` | Max locations in faceted plots | `6` |
| `max_locations_table` | Rows per page in summary tables | `15` |
| `n_worst` | Worst-behaving locations highlighted in fan plots | `18` |
| `convergence_threshold` | Relative distance from the latest value that counts as converged | `0.05` |
| `min_revision_history_days` | Reference dates newer than this many days are excluded, as not yet revised | `365` |
| `max_initial_report_lag_days` | Pairs first reported later than this many days after the reference date are treated as backfill and excluded | `60` |
