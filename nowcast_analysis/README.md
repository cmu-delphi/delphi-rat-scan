# Nowcast evaluation

[nowcast_evaluation.qmd](nowcast_evaluation.qmd) evaluates a nowcast from the Epidata V5 `/nowcast/` endpoints as it would have been used on forecast day.
Forecasts are made on Wednesdays.
For each Wednesday, the notebook takes the nowcast run on the data cutoff and compares it with the as-of value: the latest reported value at the same cutoff, which a forecaster would use without the nowcast.

It answers two questions:

1. **Is the nowcast closer to the finalized value than the as-of value?**
   This uses the weighted interval score (WIS), relative to the as-of value, by lag, by geo and over time, plus interval coverage.
   The scores match the epidata-etl nowcast evaluation.
2. **Does the nowcast track a finalized guiding indicator better than the as-of value?**
   This is the RAT-scan lagged correlation, run on the nowcast median and on the as-of data, with the difference (Δ Spearman) per lag.
   It is shown per geo over time, and across geos at each forecast date.

The template is rendered once per served nowcast artifact: a model, its parameters and its signal.
Each report shows the artifact ID in its subtitle and the full model parameters in its configuration section.
Do not use the API's `recommended` artifact: when a signal has two served configurations, it returns whichever ran last.

## Requirements

- Quarto and R, as for the other notebooks. Missing R packages are installed on the first render.
- An Epidata API key in the `DELPHI_EPIDATA_KEY` environment variable (for example in `~/.Renviron`).

## Running

[nowcast_evaluation_examples.R](nowcast_evaluation_examples.R) gets the served artifacts (those whose runs are not obsolete) from the API and renders one report per artifact.
Filter by source, signal or artifact ID:

```bash
Rscript nowcast_analysis/nowcast_evaluation_examples.R
Rscript nowcast_analysis/nowcast_evaluation_examples.R nhsn
Rscript nowcast_analysis/nowcast_evaluation_examples.R confirmed_admissions_covid_ew bde3aa63cb72cca5
```

The display name and the guiding indicator of each signal are in the `signal_info` table of the script; add a row when a new signal is served.
The reports are named `nowcast_eval_<signal>_<artifact_id>.html`.

Or render one directly from R:

```r
quarto::quarto_render(
  "nowcast_analysis/nowcast_evaluation.qmd",
  execute_params = list(
    nowcast_source = "claims_outpatient",
    artifact_id = "bde3aa63cb72cca5",
    nowcast_name = "Claims: % Outpatient Visits COVID",
    guiding_source = "nhsn",
    guiding_signal = "confirmed_admissions_covid_ew",
    guiding_name = "NHSN: Confirmed COVID Admissions",
    start_day = "2024-11-01"
  )
)
```

Use R rather than `quarto render -P`, because the Quarto CLI reads a colon in a parameter value (such as a display name) as YAML.

A claims render over two years fetches about 8 million archive rows and takes several minutes.
The API results are cached in `nowcast_analysis/nowcast_evaluation_cache/`, so later renders with the same parameters are fast.
Set `use_cache: false` to fetch again.

## Timing

The data cutoff of each source is the latest release that is available before forecasts are made on Wednesday:

| Source | Cutoff | Why |
| --- | --- | --- |
| NHSN, NSSP | the Wednesday | released on Wednesday before forecasts |
| Claims | the Tuesday | released at 8 PM, after forecasts |

A cutoff with no nowcast run on that date is not evaluated.

## Parameters

| Parameter | Description | Default |
| --- | --- | --- |
| `nowcast_source` | Nowcast source, as in `/nowcast/metadata/` | required |
| `artifact_id` | 16-character ID of the artifact; it fixes the model, its params and the signal | required |
| `nowcast_name` | Display label | signal name |
| `geo_type` | Geographic level | `state` |
| `guiding_source`, `guiding_signal`, `guiding_name` | Finalized guiding indicator for the correlation lift; leave empty for WIS only | none |
| `start_day`, `end_day` | Range of forecast dates | first nowcast run, today |
| `report_offset_days` | Days from the forecast Wednesday to the cutoff | `-1` for claims, `0` otherwise |
| `wis_lags` | Lags to score, in the nowcast's time unit | daily: 0-7 days, then weekly to `ref_lag`; weekly: all |
| `correlation_lags_weeks` | Weeks between the candidate week and the guide's anchor week | `0:4` |
| `truth_buffer_days` | Reference times this close to the latest version are not used as truth | `182` |
| `min_points_per_geo` | Minimum forecast dates for a per-geo correlation | `20` |
| `example_geos` | Geos in the example plots | `ca, ny, pa, tx` |
| `use_cache` | Reuse cached API results | `true` |

## Tests

```bash
Rscript -e 'testthat::test_dir("nowcast_analysis/tests/testthat")'
```
