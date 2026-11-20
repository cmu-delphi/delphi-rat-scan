#!/usr/bin/env Rscript
# Render nowcast_evaluation.qmd once per served nowcast artifact.
#
# Usage: Rscript nowcast_analysis/nowcast_evaluation_examples.R [filter ...]
# A filter is a source, a signal or an artifact ID. With no filters, every
# served artifact is rendered.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(quarto, here, dplyr, purrr, httr2, readr, jsonlite)

source(here::here("nowcast_analysis", "R", "nowcast_api.R"))

qmd_path <- here::here("nowcast_analysis", "nowcast_evaluation.qmd")
nowcast_sources <- c("nhsn", "claims_inpatient", "claims_outpatient")

# Display name and finalized guide per nowcast signal. Claims are scored
# against NHSN, NHSN against NSSP. ari_other has no matching guide, so it
# gets WIS only.
signal_info <- tribble(
    ~signal, ~nowcast_name, ~guiding_source, ~guiding_signal, ~guiding_name,
    "claims_outpatient_ov_pct_claims_covid", "Claims: % Outpatient Visits COVID",
    "nhsn", "confirmed_admissions_covid_ew", "NHSN: Confirmed COVID Admissions",
    "claims_outpatient_ov_pct_claims_flu", "Claims: % Outpatient Visits Flu",
    "nhsn", "confirmed_admissions_flu_ew", "NHSN: Confirmed Flu Admissions",
    "claims_outpatient_ov_pct_ari_other", "Claims: % Outpatient Visits Other ARI",
    NA, NA, NA,
    "claims_inpatient_adm_pct_claims_covid", "Claims: % Inpatient Admissions COVID",
    "nhsn", "confirmed_admissions_covid_ew", "NHSN: Confirmed COVID Admissions",
    "claims_inpatient_adm_pct_claims_flu", "Claims: % Inpatient Admissions Flu",
    "nhsn", "confirmed_admissions_flu_ew", "NHSN: Confirmed Flu Admissions",
    "claims_inpatient_adm_pct_ari_other", "Claims: % Inpatient Admissions Other ARI",
    NA, NA, NA,
    "confirmed_admissions_covid_ew", "NHSN: Confirmed COVID Admissions",
    "nssp", "pct_ed_visits_covid", "NSSP: % ED Visits COVID",
    "confirmed_admissions_flu_ew", "NHSN: Confirmed Flu Admissions",
    "nssp", "pct_ed_visits_influenza", "NSSP: % ED Visits Flu",
    "confirmed_admissions_rsv_ew", "NHSN: Confirmed RSV Admissions",
    "nssp", "pct_ed_visits_rsv", "NSSP: % ED Visits RSV"
)

# Claims nowcasts go back to 2020; two years keep a render to minutes.
start_days <- c(claims_inpatient = "2024-11-01", claims_outpatient = "2024-11-01")

served <- map(nowcast_sources, \(source) mutate(fetch_served_artifacts(source), source = source)) |>
    list_rbind() |>
    left_join(signal_info, by = "signal")

unknown_signals <- served |> filter(is.na(nowcast_name) & !grepl("ari_other", signal))
if (nrow(unknown_signals) > 0) {
    warning("No display name or guide for: ", paste(unique(unknown_signals$signal), collapse = ", "))
}

filters <- commandArgs(trailingOnly = TRUE)
if (length(filters) > 0) {
    served <- filter(served, source %in% filters | signal %in% filters | artifact_id %in% filters)
}
message("Rendering ", nrow(served), " artifact(s):\n", paste(" ", served$signal, served$artifact_id, collapse = "\n"))

pwalk(served, function(source, signal, artifact_id, nowcast_name, guiding_source, guiding_signal, guiding_name, ...) {
    execute_params <- list(
        nowcast_source = source,
        artifact_id = artifact_id,
        nowcast_name = if (is.na(nowcast_name)) NULL else nowcast_name,
        guiding_source = if (is.na(guiding_source)) NULL else guiding_source,
        guiding_signal = if (is.na(guiding_signal)) NULL else guiding_signal,
        guiding_name = if (is.na(guiding_name)) NULL else guiding_name,
        start_day = if (source %in% names(start_days)) start_days[[source]] else NULL
    )
    quarto::quarto_render(
        input = qmd_path,
        output_file = paste0("nowcast_eval_", signal, "_", artifact_id, ".html"),
        execute_params = compact(execute_params)
    )
})
