make_candidates <- function(cutoffs, lag_weeks, nowcast, as_of_value, geo_value = "pa") {
    tibble::tibble(
        forecast_date = cutoffs + 1,
        cutoff = cutoffs,
        geo_value = geo_value,
        reference_time = latest_saturday(cutoffs) - 7L * lag_weeks,
        lag = as.integer(cutoffs - latest_saturday(cutoffs)) + 7L * lag_weeks,
        nowcast = nowcast,
        as_of_value = as_of_value
    )
}

tuesdays <- seq(as.Date("2026-01-06"), by = "week", length.out = 30)

test_that("build_lift_pairs fixes the guide at the anchor week", {
    candidates <- make_candidates(tuesdays[1:2], c(0L, 1L), c(1, 2), c(3, 4))
    guide <- tibble::tibble(
        geo_value = "pa",
        reference_time = latest_saturday(tuesdays[1:2]),
        true_value = c(100, 200)
    )
    pairs <- build_lift_pairs(candidates, guide, 0:1)
    expect_equal(pairs$lag_weeks, c(0L, 1L))
    expect_equal(pairs$guide, c(100, 200))
    expect_equal(pairs$lag, c(3L, 10L))
})

test_that("build_lift_pairs drops non-Saturday references and lags not asked for", {
    candidates <- make_candidates(tuesdays[1:2], c(0L, 3L), c(1, 2), c(3, 4))
    candidates$reference_time[1] <- candidates$reference_time[1] - 1
    guide <- tibble::tibble(geo_value = "pa", reference_time = latest_saturday(tuesdays[1:2]), true_value = 1)
    expect_equal(nrow(build_lift_pairs(candidates, guide, 0:2)), 0)
})

test_that("lift_by_geo measures the gain of the nowcast over the as-of value", {
    truth <- sin(seq_along(tuesdays))
    candidates <- make_candidates(tuesdays, 0L, nowcast = truth, as_of_value = rev(truth))
    guide <- tibble::tibble(geo_value = "pa", reference_time = latest_saturday(tuesdays), true_value = truth)
    lift <- lift_by_geo(build_lift_pairs(candidates, guide, 0L), min_n = 20L)
    expect_equal(lift$cor_nowcast, 1)
    expect_equal(lift$delta_cor, 1 - lift$cor_as_of)
})

test_that("lift_by_geo drops geos with too few points", {
    candidates <- make_candidates(tuesdays[1:5], 0L, 1:5, 1:5)
    guide <- tibble::tibble(geo_value = "pa", reference_time = latest_saturday(tuesdays[1:5]), true_value = 1:5)
    expect_equal(nrow(lift_by_geo(build_lift_pairs(candidates, guide, 0L), min_n = 20L)), 0)
})

test_that("lift_by_date correlates across geos at each forecast date", {
    geos <- c("pa", "ny", "ca", "tx", "fl")
    candidates <- make_candidates(rep(tuesdays[1], 5), 0L, nowcast = 1:5, as_of_value = c(5, 1, 4, 2, 3), geo_value = geos)
    guide <- tibble::tibble(geo_value = geos, reference_time = latest_saturday(tuesdays[1]), true_value = 1:5)
    lift <- lift_by_date(build_lift_pairs(candidates, guide, 0L), min_n = 5L)
    expect_equal(nrow(lift), 1)
    expect_equal(lift$cor_nowcast, 1)
    expect_lt(lift$delta_cor, 1.5)
})
