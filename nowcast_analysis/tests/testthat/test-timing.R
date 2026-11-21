test_that("week_end_date maps every day of an epiweek to its Saturday", {
    week <- seq(as.Date("2026-11-15"), as.Date("2026-11-21"), by = "day")
    expect_equal(week_end_date(week), rep(as.Date("2026-11-21"), 7))
})

test_that("latest_saturday is the end of the last full epiweek", {
    expect_equal(latest_saturday(as.Date("2026-11-17")), as.Date("2026-11-14")) # Tuesday
    expect_equal(latest_saturday(as.Date("2026-11-18")), as.Date("2026-11-14")) # Wednesday
    expect_equal(latest_saturday(as.Date("2026-11-21")), as.Date("2026-11-21")) # Saturday
    expect_equal(latest_saturday(as.Date("2026-11-22")), as.Date("2026-11-21")) # Sunday
})

test_that("forecast_cutoffs are Wednesdays shifted by the report offset", {
    cutoffs <- forecast_cutoffs("2026-11-01", "2026-11-30", -1L)
    expect_equal(cutoffs$forecast_date, as.Date(c("2026-11-04", "2026-11-11", "2026-11-18", "2026-11-25")))
    expect_true(all(weekdays(cutoffs$cutoff) == "Tuesday"))
    expect_equal(forecast_cutoffs("2026-11-04", "2026-11-04", 0L)$cutoff, as.Date("2026-11-04"))
})

test_that("claims sources use the Tuesday release", {
    expect_equal(default_report_offset("claims_outpatient"), -1L)
    expect_equal(default_report_offset("nhsn"), 0L)
})

test_that("default_daily_lags is daily for a week, then weekly up to ref_lag", {
    expect_equal(default_daily_lags(60), c(0:7, 14L, 21L, 28L, 35L, 42L, 49L, 56L))
})

test_that("anchor lags from a Tuesday cutoff land on Saturdays", {
    tuesday <- as.Date("2026-11-17")
    lags <- anchor_lags_days(wday0(tuesday), 0:2)
    expect_equal(lags, c(3L, 10L, 17L))
    expect_true(all(weekdays(tuesday - lags) == "Saturday"))
})
