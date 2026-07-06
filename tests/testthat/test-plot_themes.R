test_that("theme_landscape composes the minimal base theme (H1 regression)", {
  # H1: theme_landscape() once evaluated theme_minimal() and %+replace% as
  # discarded bare statements and returned only the theme() overrides, so
  # landscapes silently fell back to ggplot's grey default panel. A correctly
  # composed built-in theme is complete; the overrides-only theme was not.
  expect_true(isTRUE(attr(theme_landscape(), "complete")))
})
