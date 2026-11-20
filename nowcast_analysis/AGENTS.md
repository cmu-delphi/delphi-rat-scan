# nowcast_analysis

Evaluates Epidata V5 nowcasts as they would be used on forecast day (Wednesday), against the as-of value a forecaster would otherwise use.
One parameterized template, rendered once per nowcast.

## Files

- `nowcast_evaluation.qmd`: the report. Sections: configuration, data, nowcast overview, WIS (by lag, geo, time; coverage), correlation lift against a finalized guiding indicator.
- `nowcast_evaluation_examples.R`: the list of nowcasts and their guides; renders them all or the named ones.
- `R/` (sourced by the qmd and the tests; no package):
  - `timing.R`: epiweek and cutoff dates. `forecast_cutoffs()`, `latest_saturday()`, `week_end_date()`, `default_report_offset()` (claims use the Tuesday release), `default_daily_lags()`, `anchor_lags_days()`.
  - `nowcast_api.R`: `/nowcast/metadata/` and `/nowcast/archive/` over httr2 (epidatr has no wrapper). `fetch_nowcast_archive()` moves weekly reference times to the epiweek-ending Saturday and sets `lag = -horizon`. `exclusions_from_params()` reads training exclusions from the artifact params.
  - `as_of_baseline.R`: V5 archive to `epi_archive`, as-of values per cutoff with fill forward, finalized values with a truth buffer.
  - `scoring.R`: WIS, log WIS, coverage and the as-of baseline score, matching `compute_scores.sql` / `score_null_nowcast.sql` in epidata-etl; `relative_scores()` is a ratio of sums; `apply_exclusions()` matches `scoring_exclusions.py`.
  - `correlation_lift.R`: `build_lift_pairs()` (guide fixed at the anchor week, candidate `lag_weeks` before it), `lift_by_geo()` (over time), `lift_by_date()` (across geos).
  - `plot_theme.R`: RAT-scan theme and the fixed nowcast / as-of / finalized colours.
- `tests/testthat/`: unit tests of `R/`. Run `Rscript -e 'testthat::test_dir("nowcast_analysis/tests/testthat")'` from the repo root.

## Conventions

- A forecast date is a Wednesday; its cutoff is `forecast_date + report_offset_days`. Only runs with `report_time == cutoff` are used, so nowcast and as-of value use the same release.
- All weekly values are keyed by the Saturday that ends the epiweek (V5 convention). For daily 7-day averages, only Saturdays enter the correlation lift.
- Truth is the latest value minus `truth_buffer_days` (default 182), not the model's `ref_lag`, which deliberately cuts off rare late revisions.
- API results are cached in `nowcast_evaluation_cache/`, keyed by a hash of the params.
