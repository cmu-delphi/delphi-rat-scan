# Correlation lift: does the nowcast track a finalized guiding indicator
# better than the as-of value that was available at the same cutoff?
#
# For a cutoff, the anchor is the Saturday that ends the latest full
# epiweek. The guide is its finalized value for the anchor week. The
# candidate is the value for the week that ends lag_weeks weeks before the
# anchor, once from the nowcast median and once from the as-of data. This is
# the lag convention of the RAT-scan correlation notebook: the guide stays
# fixed and the candidate moves back in time.

# candidates: forecast_date, cutoff, geo_value, reference_time, nowcast,
#   as_of_value. guide_final: geo_value, reference_time, true_value.
# Returns one row per (forecast_date, geo_value, lag_weeks) that has the
# nowcast, the as-of value and the guide.
build_lift_pairs <- function(candidates, guide_final, lags_weeks) {
    candidates |>
        dplyr::mutate(anchor = latest_saturday(cutoff)) |>
        dplyr::mutate(lag_days = as.integer(anchor - reference_time)) |>
        dplyr::filter(lag_days %% 7L == 0L, (lag_days %/% 7L) %in% lags_weeks) |>
        dplyr::mutate(lag_weeks = lag_days %/% 7L) |>
        dplyr::inner_join(
            guide_final |> dplyr::rename(anchor = reference_time, guide = true_value),
            by = c("geo_value", "anchor")
        ) |>
        dplyr::filter(!is.na(nowcast), !is.na(as_of_value), !is.na(guide)) |>
        dplyr::select(forecast_date, cutoff, anchor, geo_value, lag_weeks, lag, nowcast, as_of_value, guide)
}

# Spearman correlation with the guide for both candidates on the same rows,
# and their difference. Groups with fewer than min_n rows are dropped.
correlation_lift <- function(pairs, by, min_n) {
    pairs |>
        dplyr::summarize(
            n = dplyr::n(),
            cor_nowcast = if (n >= min_n) safe_spearman(nowcast, guide) else NA_real_,
            cor_as_of = if (n >= min_n) safe_spearman(as_of_value, guide) else NA_real_,
            .by = dplyr::all_of(by)
        ) |>
        dplyr::filter(!is.na(cor_nowcast), !is.na(cor_as_of)) |>
        dplyr::mutate(delta_cor = cor_nowcast - cor_as_of)
}

# Spearman correlation, NA when either side is constant.
safe_spearman <- function(xx, yy) {
    if (dplyr::n_distinct(xx) < 2 || dplyr::n_distinct(yy) < 2) {
        return(NA_real_)
    }
    stats::cor(xx, yy, method = "spearman")
}

# Per-geo correlations over forecast dates: the time-series view.
lift_by_geo <- function(pairs, min_n = 20L) {
    correlation_lift(pairs, c("geo_value", "lag_weeks"), min_n)
}

# Cross-geo correlations at each forecast date: the RAT-scan real-time view.
lift_by_date <- function(pairs, min_n = 5L) {
    correlation_lift(pairs, c("forecast_date", "lag_weeks"), min_n)
}
