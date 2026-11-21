levels <- c(0.05, 0.1, 0.2, 0.5, 0.8, 0.9, 0.95)

one_forecast <- function(values, truth) {
    tibble::tibble(key = "a", quantile_level = levels, value = values, true_value = truth)
}

test_that("WIS is 2 x the mean pinball loss over the stored levels", {
    values <- c(1, 2, 3, 4, 5, 6, 7)
    truth <- 4.5
    expected <- mean(2 * ifelse(truth >= values, levels * (truth - values), (1 - levels) * (values - truth)))
    scores <- score_quantiles(one_forecast(values, truth), "key")
    expect_equal(scores$wis, expected)
    expect_equal(scores$ae_median, 0.5)
    expect_equal(scores$median, 4)
})

test_that("a point mass at the truth scores zero", {
    scores <- score_quantiles(one_forecast(rep(10, 7), 10), "key")
    expect_equal(scores$wis, 0)
    expect_equal(scores$log_wis, 0)
    expect_true(scores$cover_60 && scores$cover_80 && scores$cover_90)
})

test_that("a point forecast has the same WIS as the as-of baseline score", {
    point <- score_quantiles(one_forecast(rep(3, 7), 7), "key")
    expect_equal(point$wis, score_point(3, 7)$null_wis)
})

test_that("crossed quantiles are sorted before scoring", {
    crossed <- score_quantiles(one_forecast(c(7, 2, 3, 4, 5, 6, 1), 4), "key")
    ordered <- score_quantiles(one_forecast(1:7, 4), "key")
    expect_equal(crossed$wis, ordered$wis)
    expect_equal(crossed$cover_90, ordered$cover_90)
})

test_that("a forecast with a missing quantile scores NA", {
    scores <- score_quantiles(one_forecast(c(1, 2, NA, 4, 5, 6, 7), 4), "key")
    expect_true(is.na(scores$wis))
})

test_that("interval coverage uses the central interval", {
    scores <- score_quantiles(one_forecast(1:7, 6.5), "key")
    expect_false(scores$cover_60) # [3, 5]
    expect_false(scores$cover_80) # [2, 6]
    expect_true(scores$cover_90) # [1, 7]
})

test_that("l1_calibration matches the ETL formula", {
    scores <- score_quantiles(one_forecast(1:7, 4), "key")
    expect_equal(scores$l1_calibration, mean(abs(levels - (4 <= 1:7))))
})

test_that("relative_scores is a ratio of sums on rows with both scores", {
    scores <- tibble::tibble(
        lag = c(0, 0, 0),
        wis = c(1, 3, NA), log_wis = c(1, 1, 1),
        null_wis = c(2, 2, 2), null_log_wis = c(4, 4, 4)
    )
    rel <- relative_scores(scores, "lag")
    expect_equal(rel$n, 2)
    expect_equal(rel$rel_wis, 1)
    expect_equal(rel$rel_log_wis, 0.25)
})

test_that("apply_exclusions drops rows by report or reference window", {
    rows <- tibble::tibble(
        report_time = as.Date(c("2025-10-01", "2025-12-01", "2025-12-01", "2025-12-01")),
        reference_time = as.Date(c("2025-09-01", "2025-11-15", "2025-09-20", "2025-11-29")),
        geo_value = c("pa", "pa", "pa", "ny")
    )
    exclusions <- tibble::tibble(
        start = as.Date("2025-09-27"), end = as.Date("2025-11-13"),
        geo_type = NA_character_, geo_values = list(character()), reason = "shutdown"
    )
    # Row 1: report in window. Row 3: week ending 2025-09-20 is before the
    # window. Row 2: week ending 2025-11-15 starts inside it.
    kept <- apply_exclusions(rows, exclusions, "state")
    expect_equal(kept$reference_time, as.Date(c("2025-09-20", "2025-11-29")))
})

test_that("apply_exclusions with geo values only drops those geos", {
    rows <- tibble::tibble(
        report_time = as.Date(c("2025-10-01", "2025-10-01")),
        reference_time = as.Date(c("2025-09-01", "2025-09-01")),
        geo_value = c("pa", "ny")
    )
    exclusions <- tibble::tibble(
        start = as.Date("2025-09-27"), end = as.Date("2025-11-13"),
        geo_type = "state", geo_values = list("ny"), reason = "ny outage"
    )
    expect_equal(apply_exclusions(rows, exclusions, "state")$geo_value, "pa")
    expect_equal(nrow(apply_exclusions(rows, exclusions, "hhs")), 2)
})
