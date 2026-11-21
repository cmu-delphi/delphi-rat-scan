# Quantile scores, matching include/sql/nowcasting/compute_scores.sql and
# score_null_nowcast.sql of epidata-etl.
#
# WIS is the mean over the stored quantile levels of 2 x the pinball loss.
# log_wis is the same on log(x + 1). The as-of baseline is a point forecast,
# so its WIS is the absolute error.

pinball_loss <- function(quantile_level, prediction, truth) {
    ifelse(
        truth >= prediction,
        quantile_level * (truth - prediction),
        (1 - quantile_level) * (prediction - truth)
    )
}

# predictions: one row per (key columns, quantile_level) with value and
# true_value. Quantiles are sorted within each key first, as in the ETL
# evaluation, so that crossed quantiles do not inflate interval coverage.
score_quantiles <- function(predictions, key_cols) {
    predictions |>
        dplyr::arrange(dplyr::pick(dplyr::all_of(key_cols)), quantile_level) |>
        dplyr::mutate(value = sort(value, na.last = TRUE), .by = dplyr::all_of(key_cols)) |>
        dplyr::summarize(
            wis = mean(2 * pinball_loss(quantile_level, value, true_value)),
            log_wis = mean(2 * pinball_loss(quantile_level, log1p(value), log1p(true_value))),
            ae_median = abs(true_value[quantile_level == 0.5][1] - value[quantile_level == 0.5][1]),
            l1_calibration = mean(abs(quantile_level - (true_value <= value))),
            cover_60 = interval_covers(quantile_level, value, true_value, 0.6),
            cover_80 = interval_covers(quantile_level, value, true_value, 0.8),
            cover_90 = interval_covers(quantile_level, value, true_value, 0.9),
            median = value[quantile_level == 0.5][1],
            true_value = true_value[1],
            .by = dplyr::all_of(key_cols)
        )
}

# Is the truth in the central interval of the given width? NA when the
# interval's quantile levels are not stored.
interval_covers <- function(quantile_level, value, truth, width) {
    lower <- value[abs(quantile_level - (1 - width) / 2) < 1e-9]
    upper <- value[abs(quantile_level - (1 + width) / 2) < 1e-9]
    if (length(lower) != 1 || length(upper) != 1) {
        return(NA)
    }
    truth[1] >= lower && truth[1] <= upper
}

score_point <- function(prediction, truth) {
    tibble::tibble(
        null_wis = abs(truth - prediction),
        null_log_wis = abs(log1p(truth) - log1p(prediction))
    )
}

# Relative scores per group: sum of model scores over sum of baseline scores
# on the same keys, as in the ETL cross-lag charts. Below 1 means the
# nowcast beats the as-of value.
relative_scores <- function(scores, by) {
    scores |>
        dplyr::filter(!is.na(wis), !is.na(null_wis)) |>
        dplyr::summarize(
            n = dplyr::n(),
            rel_wis = sum(wis) / sum(null_wis),
            rel_log_wis = sum(log_wis) / sum(null_log_wis),
            wis = mean(wis),
            null_wis = mean(null_wis),
            .by = dplyr::all_of(by)
        )
}

# Drop rows in a training exclusion window, by report or reference time, as
# in scoring_exclusions.py of epidata-etl. A reference time ends its week,
# so the week is in the window if any of its 7 days is.
apply_exclusions <- function(rows, exclusions, geo_type) {
    for (ii in seq_len(nrow(exclusions))) {
        rule <- exclusions[ii, ]
        in_window <- dplyr::between(rows$report_time, rule$start, rule$end) |
            dplyr::between(rows$reference_time, rule$start, rule$end + 6)
        rule_geos <- rule$geo_values[[1]]
        if (!is.na(rule$geo_type) && length(rule_geos) > 0) {
            in_window <- in_window & rule$geo_type == geo_type & rows$geo_value %in% rule_geos
        }
        rows <- rows[!in_window, ]
    }
    rows
}
