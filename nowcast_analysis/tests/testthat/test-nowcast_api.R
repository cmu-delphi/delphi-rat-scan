test_that("exclusions_from_params reads empty geo objects as all geos", {
    params <- jsonlite::fromJSON(
        '{"exclusions": [
            {"end": "2025-11-13", "start": "2025-09-27", "reason": "shutdown", "geo_type": {}, "geo_values": {}},
            {"end": "2025-01-10", "start": "2025-01-01", "reason": "outage", "geo_type": "state", "geo_values": ["ny", "nj"]}
        ]}',
        simplifyVector = FALSE
    )
    exclusions <- exclusions_from_params(params)
    expect_equal(exclusions$start, as.Date(c("2025-09-27", "2025-01-01")))
    expect_equal(exclusions$geo_type, c(NA, "state"))
    expect_equal(exclusions$geo_values, list(character(), c("ny", "nj")))
})

test_that("exclusions_from_params handles params without exclusions", {
    expect_equal(nrow(exclusions_from_params(list())), 0)
})

test_that("served_artifact_ids keeps artifacts with a run that is not obsolete", {
    runs <- tibble::tibble(
        artifact_id = c("aaa", "aaa", "bbb", "ccc"),
        obsolete_at = c("2026-01-01 00:00:00+00", NA, "2026-01-01 00:00:00+00", "")
    )
    expect_equal(served_artifact_ids(runs), c("aaa", "ccc"))
})

test_that("params_table shows scalars as text, nested values as JSON, and no exclusions", {
    params <- jsonlite::fromJSON(
        '{"ref_lag": 28, "probs": [0.1, 0.5, 0.9], "weekday_groups": {"wed": ["Wed"]},
          "lp_solver": "glpk", "exclusions": [{"start": "2025-01-01"}]}',
        simplifyVector = FALSE
    )
    table <- params_table(params)
    expect_equal(table$parameter, c("lp_solver", "probs", "ref_lag", "weekday_groups"))
    expect_equal(table$value, c("glpk", "[0.1,0.5,0.9]", "28", '{"wed":["Wed"]}'))
})
