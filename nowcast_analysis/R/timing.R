# Date alignment for forecast-day evaluation.
#
# All weekly values are keyed by the Saturday that ends their epiweek
# (Sunday-Saturday), which is the V5 API convention. A daily 7-day average
# on a Saturday covers the same days as that epiweek.

# Day of week with Sunday = 0 and Saturday = 6.
wday0 <- function(dates) as.integer(format(as.Date(dates), "%w"))

week_end_date <- function(dates) {
    dates <- as.Date(dates)
    dates + (6L - wday0(dates))
}

# Latest Saturday on or before each date: the end of the last full epiweek.
latest_saturday <- function(dates) {
    dates <- as.Date(dates)
    dates - (wday0(dates) + 1L) %% 7L
}

# Source releases that land after Wednesday forecasts are made use the
# Tuesday release instead.
default_report_offset <- function(source) {
    if (startsWith(source, "claims_")) -1L else 0L
}

# Data cutoff for each forecast Wednesday in [start_day, end_day].
forecast_cutoffs <- function(start_day, end_day, report_offset_days) {
    start_day <- as.Date(start_day)
    first_wednesday <- start_day + (3L - wday0(start_day)) %% 7L
    wednesdays <- seq(first_wednesday, as.Date(end_day), by = "week")
    tibble::tibble(forecast_date = wednesdays, cutoff = wednesdays + report_offset_days)
}

# Default claims lags: every day for the first week, then weekly to ref_lag.
default_daily_lags <- function(ref_lag) {
    sort(unique(c(0:7, seq(14L, ref_lag, by = 7L))))
}

# Lags (in days) from a cutoff back to the Saturday k weeks before the
# latest full epiweek.
anchor_lags_days <- function(cutoff_wday0, lags_weeks) {
    (cutoff_wday0 + 1L) %% 7L + 7L * lags_weeks
}
