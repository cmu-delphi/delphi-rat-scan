# As-of values and finalized values from a V5 archive.
#
# The as-of value is the baseline a forecaster has without a nowcast: the
# latest reported value at the cutoff. A reference time that has no value
# yet gets the latest earlier value of its geo (fill forward), the same as
# the null_fill_forward nowcast of the ETL evaluation.

# V5 archive rows -> epi_archive. Versions are UTC dates of report_time;
# for two reports on one date, the later one wins.
archive_from_v5 <- function(v5_rows) {
    v5_rows |>
        dplyr::mutate(version = as.Date(report_time)) |>
        dplyr::slice_max(report_time, n = 1, with_ties = FALSE,
                         by = c(geo_value, reference_time, version)) |>
        dplyr::transmute(geo_value, time_value = reference_time, version, value) |>
        epiprocess::as_epi_archive(compactify = TRUE)
}

# For each key (cutoff, geo_value, reference_time): the value as of the
# cutoff, filled forward from at most max_fill_days earlier.
as_of_values <- function(archive, keys, max_fill_days = 60L) {
    keys |>
        dplyr::group_split(cutoff) |>
        purrr::map(\(cutoff_keys) {
            cutoff <- cutoff_keys$cutoff[[1]]
            snapshot <- epiprocess::epix_as_of(
                archive, min(cutoff, archive$versions_end),
                min_time_value = min(cutoff_keys$reference_time) - max_fill_days
            ) |>
                tibble::as_tibble() |>
                dplyr::select(geo_value, as_of_reference_time = time_value, as_of_value = value) |>
                dplyr::filter(!is.na(as_of_value))
            cutoff_keys |>
                dplyr::left_join(
                    snapshot,
                    by = dplyr::join_by(geo_value, closest(reference_time >= as_of_reference_time))
                ) |>
                dplyr::mutate(
                    as_of_value = dplyr::if_else(
                        reference_time - as_of_reference_time <= max_fill_days, as_of_value, NA_real_
                    ),
                    as_of_available = dplyr::coalesce(reference_time == as_of_reference_time, FALSE)
                ) |>
                dplyr::select(-as_of_reference_time)
        }) |>
        purrr::list_rbind()
}

# Latest values, without the reference times that may still be revised:
# those within truth_buffer_days of the latest version.
final_values <- function(archive, truth_buffer_days) {
    epiprocess::epix_as_of(archive, archive$versions_end) |>
        tibble::as_tibble() |>
        dplyr::filter(time_value <= archive$versions_end - truth_buffer_days) |>
        dplyr::select(geo_value, reference_time = time_value, true_value = value)
}

# Same as final_values, for a V5 snapshot (latest values only).
final_values_from_snapshot <- function(snapshot_rows, truth_buffer_days) {
    latest_version <- max(as.Date(snapshot_rows$report_time))
    snapshot_rows |>
        dplyr::filter(reference_time <= latest_version - truth_buffer_days) |>
        dplyr::select(geo_value, reference_time, true_value = value)
}
