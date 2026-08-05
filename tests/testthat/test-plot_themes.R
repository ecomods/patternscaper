test_that("theme_landscape composes the minimal base theme (H1 regression)", {
  # H1: theme_landscape() once evaluated theme_minimal() and %+replace% as
  # discarded bare statements and returned only the theme() overrides, so
  # landscapes silently fell back to ggplot's grey default panel. A correctly
  # composed built-in theme is complete; the overrides-only theme was not.
  expect_true(isTRUE(attr(theme_landscape(), "complete")))
})

test_that("theme_landscape left-aligns titles", {
  # The H1 fix above swapped a merging `+ theme()` for a replacing %+replace%,
  # which silently dropped the hjust = 0 that both ggplot2 base themes set on
  # plot.title, centring every landscape title.
  expect_equal(theme_landscape()$plot.title$hjust, 0)
  expect_equal(theme_landscape()$plot.subtitle$hjust, 0)

  # plot_single_landscape() overrides plot.title again; that must not undo it
  l <- create_landscape("sharp", width = 20, height = 20)
  p <- plot_landscapes(l, titles = "Some title")
  expect_equal(ggplot2::calc_element("plot.title", p$theme)$hjust, 0)
})
