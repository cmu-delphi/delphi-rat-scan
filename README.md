# Delphi RAT-SCAN

RAT-SCAN (Rapid Assessment Tool for Signal Correlation and iNformation) is a set of parameterized Quarto notebooks for analyzing epidemiological indicators in the Delphi data pipeline.

## Notebooks

| Folder                         | Notebook                                                                           | Purpose                                                                                                                          |
| ------------------------------ | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| [`eda/`](eda/)                 | [`indicator_eda.qmd`](eda/indicator_eda.qmd)                                       | Characteristics, coverage, missingness and revisions of one or more indicators                                                   |
| [`correlation/`](correlation/) | [`indicator_correlation_single.qmd`](correlation/indicator_correlation_single.qmd) | Candidate vs one reference indicator: overlays, correlation and lags                                                             |
|                                | [`indicator_correlation_multi.qmd`](correlation/indicator_correlation_multi.qmd)   | Candidate vs several reference indicators                                                                                        |
| [`revision/`](revision/)       | [`indicator_revision.qmd`](revision/indicator_revision.qmd)                        | Revisions of one signal: bias of first reports, how fast values stabilize, and variation by location, season and signal features |

## Installation

- **R 4.1+**: from [CRAN](https://cran.r-project.org/) or `brew install --cask r`. [RStudio](https://posit.co/download/rstudio-desktop/) and [Positron](https://positron.posit.co/) are optional editors.
- **Quarto CLI**: from the [Quarto website](https://quarto.org/docs/get-started/) or `brew install --cask quarto`. The `quarto` R package renders from R but still needs the CLI.
- **R packages**: each notebook installs what it is missing on first run.

## Rendering

Pass params on the command line or from R. For example, an EDA of NSSP COVID ED visits by state:

```bash
quarto render eda/indicator_eda.qmd -P source:nssp -P signal:pct_ed_visits_covid -P geo_type:state
```

```r
quarto::quarto_render("eda/indicator_eda.qmd", execute_params = list(
  source = "nssp", signal = "pct_ed_visits_covid", geo_type = "state"
))
```
