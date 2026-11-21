v5_rows <- tibble::tribble(
    ~geo_value, ~reference_time, ~report_time, ~value,
    "pa", "2026-11-01", "2026-11-02 08:00:00", 10,
    "pa", "2026-11-01", "2026-11-05 08:00:00", 12,
    "pa", "2026-11-02", "2026-11-03 08:00:00", 20,
    "pa", "2026-11-02", "2026-11-03 20:00:00", 21,
    "pa", "2026-11-03", "2026-11-06 08:00:00", 30
) |>
    dplyr::mutate(reference_time = as.Date(reference_time), report_time = as.POSIXct(report_time, tz = "UTC"))

test_that("archive_from_v5 keeps the later of two reports on one date", {
    archive <- archive_from_v5(v5_rows)
    snapshot <- epiprocess::epix_as_of(archive, as.Date("2026-11-03"))
    expect_equal(snapshot$value[snapshot$time_value == as.Date("2026-11-02")], 21)
})

test_that("as_of_values uses the data at the cutoff and fills forward", {
    archive <- archive_from_v5(v5_rows)
    keys <- tibble::tibble(
        cutoff = as.Date("2026-11-04"),
        geo_value = "pa",
        reference_time = as.Date(c("2026-11-01", "2026-11-02", "2026-11-03"))
    )
    as_of <- as_of_values(archive, keys)
    expect_equal(as_of$as_of_value, c(10, 21, 21))
    expect_equal(as_of$as_of_available, c(TRUE, TRUE, FALSE))
})

test_that("as_of_values does not fill past max_fill_days", {
    archive <- archive_from_v5(v5_rows)
    keys <- tibble::tibble(cutoff = as.Date("2026-11-30"), geo_value = "pa", reference_time = as.Date("2026-11-20"))
    expect_true(is.na(as_of_values(archive, keys, max_fill_days = 7L)$as_of_value))
})

test_that("final_values drops reference times inside the truth buffer", {
    archive <- archive_from_v5(v5_rows)
    final <- final_values(archive, truth_buffer_days = 4)
    expect_equal(final$reference_time, as.Date(c("2026-11-01", "2026-11-02")))
    expect_equal(final$true_value, c(12, 21))
})
