#' Default theme for package landscape plots
#'
#' A minimal theme designed specifically for landscape visualizations, with no
#' axis labels, grid lines, or other elements that might distract from the
#' spatial pattern display.
#'
#' @param base_size Base font size
#' @param base_family Base font family
#' @param ... Additional theme elements to override defaults
#'
#' @return A ggplot2 theme object
#' @keywords internal
#' @importFrom ggplot2 theme_minimal theme element_blank rel %+replace%
#' @importFrom ggtext element_markdown
theme_landscape <- function(base_size = 9, base_family = "", ...) {
  ggplot2::theme_minimal(
    base_size = base_size,
    base_family = base_family
  ) %+replace%
    ggplot2::theme(
      # Text elements. hjust is set explicitly because %+replace% discards the
      # base theme's plot.title, and with it the hjust = 0 that theme_minimal()
      # sets; without it the title would inherit 0.5 from the parent text
      # element.
      plot.title = ggtext::element_markdown(size = ggplot2::rel(1.2), hjust = 0),
      plot.subtitle = ggtext::element_markdown(
        size = ggplot2::rel(0.9),
        hjust = 0
      ),

      # Axis elements
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),

      # Grid elements
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_blank(),

      # Include any additional theme elements
      ...
    )
}
