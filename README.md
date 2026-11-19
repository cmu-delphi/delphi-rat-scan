# Delphi RAT-SCAN

This repository contains the Delphi RAT-SCAN (Rapid Assessment Tool for Signal Correlation and iNformation), a set of parameterized Quarto notebooks for analyzing and tracking epidemiological indicators in the Delphi data pipeline.

## Notebooks

*   [`indicator_analysis/indicator_evaluation.qmd`](indicator_analysis/indicator_evaluation.qmd) performs candidate-only exploratory data analysis (EDA) to understand signal characteristics, coverage, missingness, and versioning/revision behavior.
*   [`indicator_analysis/indicator_correlation.qmd`](indicator_analysis/indicator_correlation.qmd) evaluates a candidate indicator against a guiding indicator (presumed ground truth) to assess its nowcasting/forecasting value via EDA overlays and correlation/lag analyses.
*   [`indicator_analysis/indicator_multi_comparison.qmd`](indicator_analysis/indicator_multi_comparison.qmd) evaluates one candidate indicator against multiple reference indicators in a single pairwise comparison report.
*   [`revision_analysis/revision_analysis.qmd`](revision_analysis/revision_analysis.qmd) tracks versioned time series revisions to determine how long, on average, a series continues to receive revisions after its first publication.

Each folder's README lists the notebook params and how to run them on API or local data.

## Rendering a notebook

The notebooks are templates: pass params when rendering. For example:

```bash
quarto render indicator_analysis/indicator_evaluation.qmd \
  -P source:nssp \
  -P signal:smoothed_pct_ed_visits_covid \
  -P geo_type:state
```

Rendered reports are not committed here (`*.html` is gitignored).

## Publishing analyses

Analyses meant for sharing, and the site that hosts them, live in [analysis-notebooks](https://github.com/cmu-delphi/analysis-notebooks). That repo stores each report's notebook and params, renders them with this repo's notebooks, and publishes the HTML to its gh-pages branch.
