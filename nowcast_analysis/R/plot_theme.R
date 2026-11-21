# Plot theme of the RAT-scan notebooks, with fixed colours for the three
# series that every nowcast plot compares.

version_colours <- c(
    nowcast = "#C41230",
    as_of = "#007BC0",
    final = "#172431"
)

version_labels <- c(
    nowcast = "Nowcast median",
    as_of = "As of cutoff",
    final = "Finalized"
)

# Diverging fill for ratios around 1: blue is better than the as-of value,
# red is worse.
scale_fill_relative <- function(name, limits = c(0.25, 4)) {
    ggplot2::scale_fill_gradient2(
        name = name,
        low = version_colours[["as_of"]], mid = "gray92", high = version_colours[["nowcast"]],
        midpoint = 0, trans = "log2", limits = limits,
        oob = \(xx, range) scales::squish(xx, range, only.finite = FALSE),
        labels = scales::label_number(accuracy = 0.01)
    )
}

set_rat_scan_theme <- function() {
    ggplot2::theme_set(
        ggplot2::theme_minimal(base_size = 13) +
            ggplot2::theme(
                plot.title = ggtext::element_markdown(hjust = 0.5, size = 15, face = "bold", margin = ggplot2::margin(b = 6)),
                plot.subtitle = ggplot2::element_text(hjust = 0.5, color = "gray50", margin = ggplot2::margin(b = 10)),
                plot.caption = ggtext::element_markdown(hjust = 0, color = "gray50", margin = ggplot2::margin(t = 10)),
                panel.grid = ggplot2::element_line(linetype = 2, linewidth = 0.3, color = "gray90"),
                panel.grid.minor = ggplot2::element_blank(),
                legend.position = "top",
                strip.text = ggtext::element_markdown(hjust = 0.5, size = 11, face = "bold", margin = ggplot2::margin(t = 6, b = 6)),
                strip.background = ggplot2::element_rect(fill = "gray95", linetype = "blank"),
                panel.border = ggplot2::element_rect(color = "gray95", fill = NA)
            )
    )
}
