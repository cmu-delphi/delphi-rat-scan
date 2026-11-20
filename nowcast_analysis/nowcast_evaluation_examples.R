#!/usr/bin/env Rscript
# Render nowcast_evaluation.qmd once per nowcast.
#
# Usage: Rscript nowcast_analysis/nowcast_evaluation_examples.R [name ...]
# With no names, all nowcasts below are rendered.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(quarto, here, purrr)

qmd_path <- here::here("nowcast_analysis", "nowcast_evaluation.qmd")

# Claims nowcasts are scored against NHSN; ari_other has no NHSN partner, so
# it gets WIS only. NHSN nowcasts are scored against NSSP.
claims_start <- "2024-11-01"
nowcasts <- list(
    claims_outpatient_covid = list(
        nowcast_source = "claims_outpatient",
        nowcast_signal = "claims_outpatient_ov_pct_claims_covid",
        nowcast_name = "Claims: % Outpatient Visits COVID",
        guiding_source = "nhsn",
        guiding_signal = "confirmed_admissions_covid_ew",
        guiding_name = "NHSN: Confirmed COVID Admissions",
        start_day = claims_start
    ),
    claims_outpatient_flu = list(
        nowcast_source = "claims_outpatient",
        nowcast_signal = "claims_outpatient_ov_pct_claims_flu",
        nowcast_name = "Claims: % Outpatient Visits Flu",
        guiding_source = "nhsn",
        guiding_signal = "confirmed_admissions_flu_ew",
        guiding_name = "NHSN: Confirmed Flu Admissions",
        start_day = claims_start
    ),
    claims_outpatient_ari_other = list(
        nowcast_source = "claims_outpatient",
        nowcast_signal = "claims_outpatient_ov_pct_ari_other",
        nowcast_name = "Claims: % Outpatient Visits Other ARI",
        start_day = claims_start
    ),
    claims_inpatient_covid = list(
        nowcast_source = "claims_inpatient",
        nowcast_signal = "claims_inpatient_adm_pct_claims_covid",
        nowcast_name = "Claims: % Inpatient Admissions COVID",
        guiding_source = "nhsn",
        guiding_signal = "confirmed_admissions_covid_ew",
        guiding_name = "NHSN: Confirmed COVID Admissions",
        start_day = claims_start
    ),
    claims_inpatient_flu = list(
        nowcast_source = "claims_inpatient",
        nowcast_signal = "claims_inpatient_adm_pct_claims_flu",
        nowcast_name = "Claims: % Inpatient Admissions Flu",
        guiding_source = "nhsn",
        guiding_signal = "confirmed_admissions_flu_ew",
        guiding_name = "NHSN: Confirmed Flu Admissions",
        start_day = claims_start
    ),
    claims_inpatient_ari_other = list(
        nowcast_source = "claims_inpatient",
        nowcast_signal = "claims_inpatient_adm_pct_ari_other",
        nowcast_name = "Claims: % Inpatient Admissions Other ARI",
        start_day = claims_start
    ),
    nhsn_covid = list(
        nowcast_source = "nhsn",
        nowcast_signal = "confirmed_admissions_covid_ew",
        nowcast_name = "NHSN: Confirmed COVID Admissions",
        guiding_source = "nssp",
        guiding_signal = "pct_ed_visits_covid",
        guiding_name = "NSSP: % ED Visits COVID"
    ),
    nhsn_flu = list(
        nowcast_source = "nhsn",
        nowcast_signal = "confirmed_admissions_flu_ew",
        nowcast_name = "NHSN: Confirmed Flu Admissions",
        guiding_source = "nssp",
        guiding_signal = "pct_ed_visits_influenza",
        guiding_name = "NSSP: % ED Visits Flu"
    ),
    nhsn_rsv = list(
        nowcast_source = "nhsn",
        nowcast_signal = "confirmed_admissions_rsv_ew",
        nowcast_name = "NHSN: Confirmed RSV Admissions",
        guiding_source = "nssp",
        guiding_signal = "pct_ed_visits_rsv",
        guiding_name = "NSSP: % ED Visits RSV"
    )
)

selected <- commandArgs(trailingOnly = TRUE)
if (length(selected) == 0) selected <- names(nowcasts)
unknown <- setdiff(selected, names(nowcasts))
if (length(unknown) > 0) stop("Unknown nowcast(s): ", paste(unknown, collapse = ", "))

walk(selected, \(name) {
    quarto::quarto_render(
        input = qmd_path,
        output_file = paste0("nowcast_eval_", name, "_state.html"),
        execute_params = nowcasts[[name]]
    )
})
