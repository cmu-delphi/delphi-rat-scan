# Client for the Epidata V5 nowcast endpoints (/nowcast/metadata/ and
# /nowcast/archive/). epidatr has no wrapper for these yet.
#
# The key comes from the DELPHI_EPIDATA_KEY environment variable, the same
# one epidatr uses.

nowcast_base_url <- "https://delphi.cmu.edu/epidata/v5/nowcast/"

nowcast_request <- function(path, query) {
    httr2::request(nowcast_base_url) |>
        httr2::req_url_path_append(path) |>
        httr2::req_url_query(!!!purrr::compact(query)) |>
        httr2::req_headers(token = Sys.getenv("DELPHI_EPIDATA_KEY")) |>
        httr2::req_user_agent("delphi-rat-scan") |>
        httr2::req_timeout(900) |>
        httr2::req_retry(max_tries = 3)
}

# One row per artifact, with the model params as a list column.
# artifact_id is one or more IDs, comma-separated, or "" for all artifacts.
# The API default "recommended" is not used: when two configurations of a
# signal are served, it returns whichever ran last.
fetch_nowcast_metadata <- function(source, artifact_id) {
    artifacts <- nowcast_request("metadata/", list(
        source = source,
        artifact_id = artifact_id
    )) |>
        httr2::req_perform() |>
        httr2::resp_body_json(simplifyVector = FALSE)
    tibble::tibble(
        nowcaster = purrr::map_chr(artifacts, "nowcaster"),
        signal = purrr::map_chr(artifacts, "signal"),
        artifact_id = purrr::map_chr(artifacts, "artifact_id"),
        first_train_data = as.Date(purrr::map_chr(artifacts, "first_train_data")),
        latest_train_data = as.Date(purrr::map_chr(artifacts, "latest_train_data")),
        run_count = purrr::map_int(artifacts, "run_count"),
        params = purrr::map(artifacts, "params")
    )
}

# Artifacts of a source that are served: those with a run that is not
# obsolete. Same columns as fetch_nowcast_metadata().
fetch_served_artifacts <- function(source) {
    runs_csv <- nowcast_request("metadata/runs/", list(source = source, artifact_id = "", limit = 1e6)) |>
        httr2::req_perform() |>
        httr2::resp_body_string()
    runs <- readr::read_csv(I(runs_csv), show_col_types = FALSE, col_types = readr::cols(.default = "c"))
    fetch_nowcast_metadata(source, artifact_id = "") |>
        dplyr::filter(artifact_id %in% served_artifact_ids(runs)) |>
        dplyr::arrange(signal, artifact_id)
}

served_artifact_ids <- function(runs) {
    unique(runs$artifact_id[is.na(runs$obsolete_at) | !nzchar(runs$obsolete_at)])
}

# Model params as a two-column table. Nested values are shown as JSON.
# Exclusions are left out, because the report lists them separately.
params_table <- function(params) {
    params <- params[setdiff(sort(names(params)), "exclusions")]
    tibble::tibble(
        parameter = names(params),
        value = purrr::map_chr(unname(params), \(value) {
            if (is.list(value) || length(value) != 1) {
                as.character(jsonlite::toJSON(value, auto_unbox = TRUE))
            } else {
                as.character(value)
            }
        })
    )
}

# Training exclusion windows of an artifact, one row per rule. An empty
# geo_values list means the rule covers all geos.
exclusions_from_params <- function(params) {
    rules <- params$exclusions %||% list()
    tibble::tibble(
        start = as.Date(purrr::map_chr(rules, "start", .default = NA_character_)),
        end = as.Date(purrr::map_chr(rules, "end", .default = NA_character_)),
        geo_type = purrr::map_chr(rules, \(rule) {
            if (length(rule$geo_type) == 0) NA_character_ else as.character(rule$geo_type)
        }),
        geo_values = purrr::map(rules, \(rule) as.character(unlist(rule$geo_values))),
        reason = purrr::map_chr(rules, "reason", .default = NA_character_)
    )
}

# Quantile nowcasts for the runs whose report_time is one of report_dates.
#
# The report dates are sent in yearly batches so that each URL stays short.
# Weekly nowcasts label a week by an inner day (e.g. its Wednesday); their
# reference_time is moved to the Saturday that ends the epiweek, to match V5
# data. Lags are -horizon, in days for daily and in weeks for weekly models.
fetch_nowcast_archive <- function(source, signal, geo_type, artifact_id, report_dates,
                                  horizons = NULL, weekly = FALSE) {
    report_dates <- sort(unique(as.Date(report_dates)))
    batches <- split(report_dates, format(report_dates, "%Y"))
    csv_text <- purrr::map(batches, \(dates) {
        nowcast_request("archive/", list(
            source = source,
            signal = signal,
            geo_type = geo_type,
            artifact_id = artifact_id,
            report_time_query = paste0(dates, ":", dates, collapse = ","),
            horizon = if (is.null(horizons)) NULL else paste(horizons, collapse = ","),
            columns = "report_time,reference_time,horizon,geo_value,output_type,output_type_id,value"
        )) |>
            httr2::req_perform() |>
            httr2::resp_body_string()
    })
    nowcasts <- csv_text |>
        purrr::discard(\(text) !nzchar(text)) |>
        purrr::map(\(text) readr::read_csv(I(text), show_col_types = FALSE, col_types = readr::cols(
            report_time = readr::col_date(),
            reference_time = readr::col_date(),
            horizon = readr::col_integer(),
            geo_value = readr::col_character(),
            output_type = readr::col_character(),
            output_type_id = readr::col_double(),
            value = readr::col_double()
        ))) |>
        purrr::list_rbind()
    if (nrow(nowcasts) == 0) {
        return(tibble::tibble(
            report_time = as.Date(character()), reference_time = as.Date(character()),
            lag = integer(), geo_value = character(), quantile_level = double(), value = double()
        ))
    }
    nowcasts |>
        dplyr::filter(output_type == "quantile") |>
        dplyr::transmute(
            report_time,
            reference_time = if (weekly) week_end_date(reference_time) else reference_time,
            lag = -horizon,
            geo_value,
            quantile_level = output_type_id,
            value
        )
}
