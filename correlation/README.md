# Correlation analysis

These notebooks compare a candidate indicator against reference indicators (presumed ground truth) to assess its nowcasting/forecasting value.

- [`indicator_correlation_single.qmd`](indicator_correlation_single.qmd): one reference, with overlays, correlation and lag analyses, and revision behavior.
- [`indicator_correlation_multi.qmd`](indicator_correlation_multi.qmd): several references, each compared pairwise with the candidate.

Both take the same params. In the multi notebook, `reference_*` params are vectors with one element per reference.

## Examples

NSSP COVID ED visits against NHSN COVID admissions, from the command line:

```bash
quarto render correlation/indicator_correlation_single.qmd \
  -P candidate_source:nssp -P candidate_signal:pct_ed_visits_covid \
  -P reference_source:nhsn -P reference_signal:confirmed_admissions_covid_ew \
  -P geo_type:state -P start_day:2023-01-01 -P end_day:2025-12-31
```

The same candidate against two references with the multi notebook, from R (vector params need R or a params file):

```r
quarto::quarto_render("correlation/indicator_correlation_multi.qmd", execute_params = list(
  candidate_source = "nssp", candidate_signal = "pct_ed_visits_covid",
  candidate_name = "NSSP: % ED Visits COVID",
  reference_source = c("nhsn", "claims_outpatient"),
  reference_signal = c("confirmed_admissions_covid_ew", "claims_outpatient_ov_pct_claims_covid"),
  reference_name = c("NHSN: Confirmed COVID Admissions", "Claims: % Outpatient Visits COVID"),
  geo_type = "state", start_day = "2023-01-01", end_day = "2025-12-31"
))
```

## Data

- **Epidata API**: set each indicator's `*_source` and `*_signal`, plus `geo_type`. Only V5 sources are supported. `epidatr::epidata_meta()` lists them with their signals and geo types.
- **Local CSV**: set an indicator's `*_csv` instead of its source and signal.

Columns each local CSV (one per indicator) must or can contain:

| Column | Required | Description |
| --- | --- | --- |
| `geo_value`, `time_value`, `value` | Yes | Location, observation date and numeric value |
| `version` (or `issue`) | No | Issue date; enables the revision sections. Single notebook's `candidate_csv` only |
| `fill_method` | No | How each value was produced, as in V5 data; at most one per location |

Each indicator must be one series: one row per location and date.

## Params

| Param | Description | Default |
| --- | --- | --- |
| `candidate_source`, `candidate_signal` | Candidate source and signal | Required for API |
| `candidate_name` | Candidate label | `candidate_signal` (single); required (multi) |
| `candidate_csv` | Local candidate CSV, used instead of the API | `NULL` |
| `reference_source`, `reference_signal` | Reference source(s) and signal(s) | Required for API |
| `reference_name` | Reference label(s) | `reference_signal` (single); required (multi) |
| `reference_csv` | Local reference CSV(s); in multi, blank for API references | `NULL` |
| `geo_type` | `state`, `county`, `msa`, … | Required for API; inferred for CSV (single) |
| `start_day`, `end_day` | Date range (YYYY-MM-DD) | Full range |
| `max_locations_plot` | Max locations in plots and tables | `60` (single), `12` (multi) |
| `max_archive_locs` | Max locations fetched for version history (single only) | `60` |
| `min_archive_days` | Min days of version history for the revision analysis (single only) | `60` |
